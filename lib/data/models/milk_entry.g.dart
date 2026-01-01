// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'milk_entry.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MilkEntryAdapter extends TypeAdapter<MilkEntry> {
  @override
  final int typeId = 0;

  @override
  MilkEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MilkEntry(
      date: fields[0] as DateTime,
      morningMilk: fields[1] as double,
      eveningMilk: fields[2] as double,
      createdAt: fields[3] as DateTime,
      notes: fields[4] as String,
    );
  }

  @override
  void write(BinaryWriter writer, MilkEntry obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.date)
      ..writeByte(1)
      ..write(obj.morningMilk)
      ..writeByte(2)
      ..write(obj.eveningMilk)
      ..writeByte(3)
      ..write(obj.createdAt)
      ..writeByte(4)
      ..write(obj.notes);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MilkEntryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
