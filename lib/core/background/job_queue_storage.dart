import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/app_logger.dart';
import 'analysis_job.dart';

/// Persistent storage for analysis jobs using SharedPreferences
class JobQueueStorage {
  JobQueueStorage._();
  static final JobQueueStorage instance = JobQueueStorage._();

  static const String _jobsKey = 'analysis_jobs';
  static const String _completedJobsKey = 'completed_analysis_jobs';

  SharedPreferences? _prefs;

  Future<SharedPreferences> get _preferences async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  /// Save a new job to the queue
  Future<void> saveJob(AnalysisJob job) async {
    try {
      final prefs = await _preferences;
      final jobs = await getAllJobs();

      // Update existing or add new
      final index = jobs.indexWhere((j) => j.id == job.id);
      if (index >= 0) {
        jobs[index] = job;
      } else {
        jobs.add(job);
      }

      await _saveJobsList(prefs, jobs);
      AppLogger.d('Saved job ${job.id} to queue');
    } catch (e, stackTrace) {
      AppLogger.e('Failed to save job', error: e, stackTrace: stackTrace);
    }
  }

  /// Get all pending and processing jobs
  Future<List<AnalysisJob>> getAllJobs() async {
    try {
      final prefs = await _preferences;
      final jsonString = prefs.getString(_jobsKey);
      if (jsonString == null || jsonString.isEmpty) {
        return [];
      }

      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList
          .map((e) => AnalysisJob.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e, stackTrace) {
      AppLogger.e('Failed to get jobs, clearing corrupted data', error: e, stackTrace: stackTrace);
      try {
        final prefs = await _preferences;
        await prefs.remove(_jobsKey);
      } catch (e, st) {
        AppLogger.e('Failed to clear corrupted data', error: e, stackTrace: st);
      }
      return [];
    }
  }

  /// Get a specific job by ID
  Future<AnalysisJob?> getJob(String jobId) async {
    final jobs = await getAllJobs();
    final job = jobs.where((j) => j.id == jobId).firstOrNull;
    if (job != null) return job;

    final completedJobs = await getCompletedJobs();
    return completedJobs.where((j) => j.id == jobId).firstOrNull;
  }

  /// Get pending jobs (ready to process)
  Future<List<AnalysisJob>> getPendingJobs() async {
    final jobs = await getAllJobs();
    return jobs.where((j) => j.isPending).toList();
  }

  /// Get jobs currently being processed
  Future<List<AnalysisJob>> getProcessingJobs() async {
    final jobs = await getAllJobs();
    return jobs.where((j) => j.isProcessing).toList();
  }

  /// Update a job's status
  Future<void> updateJobStatus(
    String jobId, {
    required AnalysisJobStatus status,
    int? analysisId,
    String? errorMessage,
    List<String>? resultPhotoUrls,
  }) async {
    final jobs = await getAllJobs();
    final index = jobs.indexWhere((j) => j.id == jobId);

    if (index < 0) {
      AppLogger.w('Job $jobId not found for status update');
      return;
    }

    final job = jobs[index];
    final updatedJob = job.copyWith(
      status: status,
      analysisId: analysisId,
      errorMessage: errorMessage,
      resultPhotoUrls: resultPhotoUrls,
      completedAt: (status == AnalysisJobStatus.completed ||
                   status == AnalysisJobStatus.failed)
          ? DateTime.now()
          : null,
      retryCount: status == AnalysisJobStatus.failed
          ? job.retryCount + 1
          : job.retryCount,
    );

    jobs[index] = updatedJob;

    final prefs = await _preferences;
    await _saveJobsList(prefs, jobs);

    // If completed or failed, move to completed jobs list
    if (status == AnalysisJobStatus.completed ||
        (status == AnalysisJobStatus.failed && !updatedJob.canRetry)) {
      await _moveToCompleted(updatedJob);
    }

    AppLogger.d('Updated job $jobId status to ${status.name}');
  }

  /// Remove a job from the queue
  Future<void> removeJob(String jobId) async {
    final jobs = await getAllJobs();
    jobs.removeWhere((j) => j.id == jobId);

    final prefs = await _preferences;
    await _saveJobsList(prefs, jobs);

    AppLogger.d('Removed job $jobId from queue');
  }

  /// Get completed jobs (for history)
  Future<List<AnalysisJob>> getCompletedJobs() async {
    try {
      final prefs = await _preferences;
      final jsonString = prefs.getString(_completedJobsKey);
      if (jsonString == null || jsonString.isEmpty) {
        return [];
      }

      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList
          .map((e) => AnalysisJob.fromJson(e as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } catch (e, stackTrace) {
      AppLogger.e('Failed to get completed jobs', error: e, stackTrace: stackTrace);
      return [];
    }
  }

  /// Move job to completed list
  Future<void> _moveToCompleted(AnalysisJob job) async {
    // Remove from active jobs
    final jobs = await getAllJobs();
    jobs.removeWhere((j) => j.id == job.id);

    final prefs = await _preferences;
    await _saveJobsList(prefs, jobs);

    // Add to completed jobs (keep last 50)
    final completedJobs = await getCompletedJobs();
    completedJobs.insert(0, job);
    if (completedJobs.length > 50) {
      completedJobs.removeLast();
    }

    final completedJson = jsonEncode(completedJobs.map((j) => j.toJson()).toList());
    await prefs.setString(_completedJobsKey, completedJson);
  }

  /// Save jobs list to storage
  Future<void> _saveJobsList(SharedPreferences prefs, List<AnalysisJob> jobs) async {
    final jsonString = jsonEncode(jobs.map((j) => j.toJson()).toList());
    await prefs.setString(_jobsKey, jsonString);
  }

  /// Mark a completed job as notified (prevents duplicate snackbars)
  Future<void> markJobNotified(String jobId) async {
    try {
      final prefs = await _preferences;
      final completedJobs = await getCompletedJobs();
      final index = completedJobs.indexWhere((j) => j.id == jobId);
      if (index < 0) return;

      completedJobs[index] = completedJobs[index].copyWith(
        notifiedAt: DateTime.now(),
      );

      final completedJson =
          jsonEncode(completedJobs.map((j) => j.toJson()).toList());
      await prefs.setString(_completedJobsKey, completedJson);
    } catch (e) {
      AppLogger.w('Failed to mark job notified: $e');
    }
  }

  /// Clear all jobs (for testing/debugging)
  Future<void> clearAll() async {
    final prefs = await _preferences;
    await prefs.remove(_jobsKey);
    await prefs.remove(_completedJobsKey);
    AppLogger.d('Cleared all jobs');
  }

  /// Get count of active jobs
  Future<int> getActiveJobCount() async {
    final jobs = await getAllJobs();
    return jobs.where((j) => j.isPending || j.isProcessing).length;
  }
}
