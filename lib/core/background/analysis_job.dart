import 'dart:convert';

/// Status of an analysis job
enum AnalysisJobStatus {
  pending,
  processing,
  completed,
  failed,
}

/// Type of analysis job
enum AnalysisJobType {
  profile,
  chat,
  enhancement,
}

/// Represents an analysis job that can be persisted and resumed
class AnalysisJob {
  final String id;
  final AnalysisJobType type;
  final List<String> base64Images;
  final String language;
  final String? countryCode;
  final String? countryName;
  final int? contextProfileId; // For chat analysis
  final int? sourceAnalysisId; // For enhancement: the analysis ID to use
  final DateTime createdAt;
  final DateTime? completedAt;
  AnalysisJobStatus status;
  int? analysisId; // Set when completed successfully
  String? errorMessage;
  int retryCount;
  List<String>? resultPhotoUrls; // CDN URLs of enhanced photos (output)
  DateTime? notifiedAt; // When user was notified of completion (prevents duplicate snackbars)

  AnalysisJob({
    required this.id,
    required this.type,
    required this.base64Images,
    required this.language,
    this.countryCode,
    this.countryName,
    this.contextProfileId,
    this.sourceAnalysisId,
    required this.createdAt,
    this.completedAt,
    this.status = AnalysisJobStatus.pending,
    this.analysisId,
    this.errorMessage,
    this.retryCount = 0,
    this.resultPhotoUrls,
    this.notifiedAt,
  });

  /// Create a new profile analysis job
  factory AnalysisJob.profile({
    required String id,
    required List<String> base64Images,
    required String language,
    String? countryCode,
    String? countryName,
  }) {
    return AnalysisJob(
      id: id,
      type: AnalysisJobType.profile,
      base64Images: base64Images,
      language: language,
      countryCode: countryCode,
      countryName: countryName,
      createdAt: DateTime.now(),
    );
  }

  /// Create a new chat analysis job
  factory AnalysisJob.chat({
    required String id,
    required List<String> base64Images,
    required String language,
    int? contextProfileId,
  }) {
    return AnalysisJob(
      id: id,
      type: AnalysisJobType.chat,
      base64Images: base64Images,
      language: language,
      contextProfileId: contextProfileId,
      createdAt: DateTime.now(),
    );
  }

  /// Create a new photo enhancement job
  factory AnalysisJob.enhancement({
    required String id,
    required int sourceAnalysisId,
    required String referencePhotoBase64,
    String language = 'en',
  }) {
    return AnalysisJob(
      id: id,
      type: AnalysisJobType.enhancement,
      base64Images: [referencePhotoBase64],
      language: language,
      sourceAnalysisId: sourceAnalysisId,
      createdAt: DateTime.now(),
    );
  }

  /// Serialize to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'base64Images': base64Images,
      'language': language,
      'countryCode': countryCode,
      'countryName': countryName,
      'contextProfileId': contextProfileId,
      'sourceAnalysisId': sourceAnalysisId,
      'createdAt': createdAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'status': status.name,
      'analysisId': analysisId,
      'errorMessage': errorMessage,
      'retryCount': retryCount,
      'resultPhotoUrls': resultPhotoUrls,
      'notifiedAt': notifiedAt?.toIso8601String(),
    };
  }

  /// Deserialize from JSON
  factory AnalysisJob.fromJson(Map<String, dynamic> json) {
    final contextVal = json['contextProfileId'];
    final sourceVal = json['sourceAnalysisId'];
    final analysisVal = json['analysisId'];
    final retryVal = json['retryCount'];

    return AnalysisJob(
      id: json['id']?.toString() ?? '',
      type: AnalysisJobType.values.firstWhere(
        (e) => e.name == json['type']?.toString(),
        orElse: () => AnalysisJobType.profile,
      ),
      base64Images: (json['base64Images'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      language: json['language']?.toString() ?? 'en',
      countryCode: json['countryCode']?.toString(),
      countryName: json['countryName']?.toString(),
      contextProfileId: contextVal is int
          ? contextVal
          : (contextVal is num ? contextVal.toInt() : (contextVal is String ? int.tryParse(contextVal) : null)),
      sourceAnalysisId: sourceVal is int
          ? sourceVal
          : (sourceVal is num ? sourceVal.toInt() : (sourceVal is String ? int.tryParse(sourceVal) : null)),
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      completedAt: json['completedAt'] != null
          ? DateTime.tryParse(json['completedAt'].toString())
          : null,
      status: AnalysisJobStatus.values.firstWhere(
        (e) => e.name == json['status']?.toString(),
        orElse: () => AnalysisJobStatus.pending,
      ),
      analysisId: analysisVal is int
          ? analysisVal
          : (analysisVal is num ? analysisVal.toInt() : (analysisVal is String ? int.tryParse(analysisVal) : null)),
      errorMessage: json['errorMessage']?.toString(),
      retryCount: retryVal is int
          ? retryVal
          : (retryVal is num ? retryVal.toInt() : (retryVal is String ? int.tryParse(retryVal) ?? 0 : 0)),
      resultPhotoUrls: (json['resultPhotoUrls'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
      notifiedAt: json['notifiedAt'] != null
          ? DateTime.tryParse(json['notifiedAt'].toString())
          : null,
    );
  }

  /// Convert to JSON string
  String toJsonString() => jsonEncode(toJson());

  /// Create from JSON string
  factory AnalysisJob.fromJsonString(String jsonString) {
    return AnalysisJob.fromJson(jsonDecode(jsonString) as Map<String, dynamic>);
  }

  /// Copy with updated fields
  AnalysisJob copyWith({
    AnalysisJobStatus? status,
    int? analysisId,
    String? errorMessage,
    DateTime? completedAt,
    int? retryCount,
    List<String>? resultPhotoUrls,
    DateTime? notifiedAt,
  }) {
    return AnalysisJob(
      id: id,
      type: type,
      base64Images: base64Images,
      language: language,
      countryCode: countryCode,
      countryName: countryName,
      contextProfileId: contextProfileId,
      sourceAnalysisId: sourceAnalysisId,
      createdAt: createdAt,
      completedAt: completedAt ?? this.completedAt,
      status: status ?? this.status,
      analysisId: analysisId ?? this.analysisId,
      errorMessage: errorMessage ?? this.errorMessage,
      retryCount: retryCount ?? this.retryCount,
      resultPhotoUrls: resultPhotoUrls ?? this.resultPhotoUrls,
      notifiedAt: notifiedAt ?? this.notifiedAt,
    );
  }

  bool get isPending => status == AnalysisJobStatus.pending;
  bool get isProcessing => status == AnalysisJobStatus.processing;
  bool get isCompleted => status == AnalysisJobStatus.completed;
  bool get isFailed => status == AnalysisJobStatus.failed;
  bool get canRetry => retryCount < 3 && isFailed;
}
