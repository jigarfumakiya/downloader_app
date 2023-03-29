// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'download_table.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DownloadTableAdapter extends TypeAdapter<DownloadTable> {
  @override
  final int typeId = 1;

  @override
  DownloadTable read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DownloadTable(
      fileName: fields[1] as String,
      url: fields[2] as String,
      state: fields[3] as DownloadState,
    );
  }

  @override
  void write(BinaryWriter writer, DownloadTable obj) {
    writer
      ..writeByte(3)
      ..writeByte(1)
      ..write(obj.fileName)
      ..writeByte(2)
      ..write(obj.url)
      ..writeByte(3)
      ..write(obj.state);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DownloadTableAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
