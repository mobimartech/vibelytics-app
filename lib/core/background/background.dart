// Background processing module
//
// Provides non-blocking background analysis with job persistence and notifications.
//
// Usage:
//   import 'package:vibelytics/core/background/background.dart';
//
//   // Submit a new background job
//   final job = AnalysisJob.profile(
//     id: DateTime.now().millisecondsSinceEpoch.toString(),
//     base64Images: imageDataUris,
//     language: 'en',
//   );
//   await BackgroundTaskManager.instance.submitJob(job);
//
//   // Check job status
//   final status = await JobQueueStorage.instance.getJob(jobId);

export 'analysis_job.dart';
export 'job_queue_storage.dart';
export 'background_task_manager.dart';
