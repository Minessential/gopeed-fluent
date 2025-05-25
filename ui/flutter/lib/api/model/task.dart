import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

import 'meta.dart';

part 'task.g.dart';

enum Status { ready, running, pause, wait, error, done }

enum Protocol { http, bt }

@JsonSerializable(explicitToJson: true)
class Task extends Equatable {
  final String id;
  final String name;
  final Protocol? protocol;
  final Meta meta;
  final Status status;
  final bool uploading;
  final Progress progress;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Task({
    this.protocol,
    required this.id,
    required this.name,
    required this.meta,
    required this.status,
    required this.uploading,
    required this.progress,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object> get props => [id];

  factory Task.fromJson(Map<String, dynamic> json) => _$TaskFromJson(json);

  Map<String, dynamic> toJson() => _$TaskToJson(this);
}

@JsonSerializable()
class Progress {
  int used;
  int speed;
  int downloaded;
  int uploadSpeed;
  int uploaded;

  Progress({
    required this.used,
    required this.speed,
    required this.downloaded,
    required this.uploadSpeed,
    required this.uploaded,
  });

  factory Progress.fromJson(Map<String, dynamic> json) => _$ProgressFromJson(json);

  Map<String, dynamic> toJson() => _$ProgressToJson(this);
}
