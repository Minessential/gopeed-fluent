// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'task.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Task _$TaskFromJson(Map<String, dynamic> json) => Task(
      protocol: $enumDecodeNullable(_$ProtocolEnumMap, json['protocol']),
      id: json['id'] as String,
      name: json['name'] as String,
      meta: Meta.fromJson(json['meta'] as Map<String, dynamic>),
      status: $enumDecode(_$StatusEnumMap, json['status']),
      uploading: json['uploading'] as bool,
      progress: Progress.fromJson(json['progress'] as Map<String, dynamic>),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$TaskToJson(Task instance) {
  final val = <String, dynamic>{
    'id': instance.id,
    'name': instance.name,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('protocol', _$ProtocolEnumMap[instance.protocol]);
  val['meta'] = instance.meta.toJson();
  val['status'] = _$StatusEnumMap[instance.status]!;
  val['uploading'] = instance.uploading;
  val['progress'] = instance.progress.toJson();
  val['createdAt'] = instance.createdAt.toIso8601String();
  val['updatedAt'] = instance.updatedAt.toIso8601String();
  return val;
}

const _$ProtocolEnumMap = {
  Protocol.http: 'http',
  Protocol.bt: 'bt',
};

const _$StatusEnumMap = {
  Status.ready: 'ready',
  Status.running: 'running',
  Status.pause: 'pause',
  Status.wait: 'wait',
  Status.error: 'error',
  Status.done: 'done',
};

Progress _$ProgressFromJson(Map<String, dynamic> json) => Progress(
      used: (json['used'] as num).toInt(),
      speed: (json['speed'] as num).toInt(),
      downloaded: (json['downloaded'] as num).toInt(),
      uploadSpeed: (json['uploadSpeed'] as num).toInt(),
      uploaded: (json['uploaded'] as num).toInt(),
    );

Map<String, dynamic> _$ProgressToJson(Progress instance) => <String, dynamic>{
      'used': instance.used,
      'speed': instance.speed,
      'downloaded': instance.downloaded,
      'uploadSpeed': instance.uploadSpeed,
      'uploaded': instance.uploaded,
    };
