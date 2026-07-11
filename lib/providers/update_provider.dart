import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:stash/services/update_service.dart';

enum UpdateStatus { idle, checking, available, downloading, downloaded, error }

class UpdateState {
  final UpdateStatus status;
  final UpdateInfo? info;
  final double progress;
  final int receivedBytes;
  final int totalBytes;
  final String? error;

  const UpdateState({
    this.status = UpdateStatus.idle,
    this.info,
    this.progress = 0.0,
    this.receivedBytes = 0,
    this.totalBytes = 0,
    this.error,
  });

  UpdateState copyWith({
    UpdateStatus? status,
    UpdateInfo? info,
    double? progress,
    int? receivedBytes,
    int? totalBytes,
    String? error,
  }) {
    return UpdateState(
      status: status ?? this.status,
      info: info ?? this.info,
      progress: progress ?? this.progress,
      receivedBytes: receivedBytes ?? this.receivedBytes,
      totalBytes: totalBytes ?? this.totalBytes,
      error: error,
    );
  }
}

class UpdateNotifier extends AutoDisposeAsyncNotifier<UpdateState> {
  @override
  Future<UpdateState> build() => checkForUpdate();

  Future<UpdateState> checkForUpdate() async {
    try {
      final info = await UpdateService.fetchLatestRelease();
      if (info == null) {
        return const UpdateState(status: UpdateStatus.idle);
      }

      final isNewer = await UpdateService.isNewerVersion(info.version);
      if (!isNewer) {
        return const UpdateState(status: UpdateStatus.idle);
      }

      return UpdateState(status: UpdateStatus.available, info: info);
    } catch (e) {
      return UpdateState(status: UpdateStatus.error, error: e.toString());
    }
  }

  Future<void> download() async {
    final current = state.valueOrNull;
    if (current?.status != UpdateStatus.available || current?.info == null) return;

    state = const AsyncValue.data(UpdateState(status: UpdateStatus.downloading));

    try {
      final filePath = await UpdateService.downloadUpdate(
        current!.info!.downloadUrl,
        (progress, received, total) {
          state = AsyncValue.data(UpdateState(
            status: UpdateStatus.downloading,
            info: current.info,
            progress: progress,
            receivedBytes: received,
            totalBytes: total,
          ));
        },
      );

      state = AsyncValue.data(UpdateState(
        status: UpdateStatus.downloaded,
        info: current.info,
        progress: 1.0,
      ));

      await UpdateService.installApk(filePath);
    } catch (e) {
      state = AsyncValue.data(UpdateState(
        status: UpdateStatus.error,
        error: e.toString(),
      ));
    }
  }
}

final updateProvider = AutoDisposeAsyncNotifierProvider<UpdateNotifier, UpdateState>(
  UpdateNotifier.new,
);
