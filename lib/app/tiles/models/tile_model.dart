/// Enum representing different material types for tiles
enum MaterialType {
  slate,
  fibreCementSlate,
  interlockingTile,
  plainTile,
  concreteTile,
  pantile,
  unknown
}

/// Model class representing a roof tile with all its specifications
class TileModel {
  final String id;
  final String name;
  final String manufacturer;
  final MaterialType materialType;
  final String description;
  final bool isPublic;
  final bool isApproved;
  final String createdById;
  final DateTime createdAt;
  final DateTime? updatedAt;

  // Tile measurements (in mm)
  final double slateTileHeight; // length/height of the tile
  final double tileCoverWidth; // width of the tile
  final double minGauge; // minimum gauge/batten spacing
  final double maxGauge; // maximum gauge/batten spacing
  final double minSpacing; // minimum horizontal spacing
  final double maxSpacing; // maximum horizontal spacing
  final bool defaultCrossBonded;
  final double? leftHandTileWidth;
  final String? imageUrl;
  final String? datasheetUrl;

  /// Constructor for TileModel
  TileModel({
    required this.id,
    required this.name,
    required this.manufacturer,
    required this.materialType,
    required this.description,
    required this.isPublic,
    required this.isApproved,
    required this.createdById,
    required this.createdAt,
    this.updatedAt,
    required this.slateTileHeight,
    required this.tileCoverWidth,
    required this.minGauge,
    required this.maxGauge,
    required this.minSpacing,
    required this.maxSpacing,
    required this.defaultCrossBonded,
    this.leftHandTileWidth,
    this.imageUrl,
    this.datasheetUrl,
  });

  /// Get a string representation of the material type
  String get materialTypeString {
    switch (materialType) {
      case MaterialType.slate:
        return 'slate';
      case MaterialType.fibreCementSlate:
        return 'fibre-cement-slate';
      case MaterialType.interlockingTile:
        return 'interlocking-tile';
      case MaterialType.plainTile:
        return 'plain-tile';
      case MaterialType.concreteTile:
        return 'concrete-tile';
      case MaterialType.pantile:
        return 'pantile';
      case MaterialType.unknown:
        return 'unknown';
    }
  }

  /// Create a TileModel from a CSV row
  factory TileModel.fromCsv(Map<String, dynamic> row,
      {required String userId}) {
    final MaterialType tileType = _parseMaterialType(row['type'] ?? 'unknown');

    return TileModel(
      id: 'tile_${DateTime.now().millisecondsSinceEpoch}',
      name: row['Name'] ?? 'Unnamed Tile',
      manufacturer: row['manufacturer'] ?? 'Unknown',
      materialType: tileType,
      description:
          '${row['Name']} - ${row['type'] ?? 'unknown'} type roofing tile',
      isPublic: true,
      isApproved: true,
      createdById: userId,
      createdAt: DateTime.now(),
      slateTileHeight: double.tryParse(row['length'] ?? '0') ?? 0,
      tileCoverWidth: double.tryParse(row['width'] ?? '0') ?? 0,
      minGauge: double.tryParse(row['gauge min'] ?? '0') ?? 0,
      maxGauge: double.tryParse(row['gauge max'] ?? '0') ?? 0,
      minSpacing: double.tryParse(row['min spacing'] ?? '0') ?? 0,
      maxSpacing: double.tryParse(row['maxspacing'] ?? '0') ?? 0,
      defaultCrossBonded: (row['crossbonded'] ?? '').toLowerCase() == 'cross',
      leftHandTileWidth: double.tryParse(row['left hand tile width'] ?? '0'),
      imageUrl: row['Image'],
      datasheetUrl: row['tile datasheet link'],
    );
  }

  /// Create a copy of this TileModel with potentially modified fields
  TileModel copyWith({
    String? id,
    String? name,
    String? manufacturer,
    MaterialType? materialType,
    String? description,
    bool? isPublic,
    bool? isApproved,
    String? createdById,
    DateTime? createdAt,
    DateTime? updatedAt,
    double? slateTileHeight,
    double? tileCoverWidth,
    double? minGauge,
    double? maxGauge,
    double? minSpacing,
    double? maxSpacing,
    bool? defaultCrossBonded,
    double? leftHandTileWidth,
    String? imageUrl,
    String? datasheetUrl,
  }) {
    return TileModel(
      id: id ?? this.id,
      name: name ?? this.name,
      manufacturer: manufacturer ?? this.manufacturer,
      materialType: materialType ?? this.materialType,
      description: description ?? this.description,
      isPublic: isPublic ?? this.isPublic,
      isApproved: isApproved ?? this.isApproved,
      createdById: createdById ?? this.createdById,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      slateTileHeight: slateTileHeight ?? this.slateTileHeight,
      tileCoverWidth: tileCoverWidth ?? this.tileCoverWidth,
      minGauge: minGauge ?? this.minGauge,
      maxGauge: maxGauge ?? this.maxGauge,
      minSpacing: minSpacing ?? this.minSpacing,
      maxSpacing: maxSpacing ?? this.maxSpacing,
      defaultCrossBonded: defaultCrossBonded ?? this.defaultCrossBonded,
      leftHandTileWidth: leftHandTileWidth ?? this.leftHandTileWidth,
      imageUrl: imageUrl ?? this.imageUrl,
      datasheetUrl: datasheetUrl ?? this.datasheetUrl,
    );
  }

  /// Convert to JSON for Firebase
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'manufacturer': manufacturer,
      'materialType': materialTypeString,
      'description': description,
      'isPublic': isPublic,
      'isApproved': isApproved,
      'createdById': createdById,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt?.millisecondsSinceEpoch,
      'slateTileHeight': slateTileHeight,
      'tileCoverWidth': tileCoverWidth,
      'minGauge': minGauge,
      'maxGauge': maxGauge,
      'minSpacing': minSpacing,
      'maxSpacing': maxSpacing,
      'defaultCrossBonded': defaultCrossBonded,
      'leftHandTileWidth': leftHandTileWidth,
      'imageUrl': imageUrl,
      'datasheetUrl': datasheetUrl,
    };
  }

  /// Create a TileModel from Firebase JSON
  factory TileModel.fromJson(Map<String, dynamic> json) {
    return TileModel(
      id: json['id'] ?? 'unknown_id',
      name: json['name'] ?? 'Unknown Tile',
      manufacturer: json['manufacturer'] ?? 'Unknown',
      materialType: _parseMaterialType(json['materialType'] ?? 'unknown'),
      description: json['description'] ?? '',
      isPublic: json['isPublic'] ?? false,
      isApproved: json['isApproved'] ?? false,
      createdById: json['createdById'] ?? '',
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt'] ?? 0),
      updatedAt: json['updatedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['updatedAt'])
          : null,
      slateTileHeight: json['slateTileHeight']?.toDouble() ?? 0,
      tileCoverWidth: json['tileCoverWidth']?.toDouble() ?? 0,
      minGauge: json['minGauge']?.toDouble() ?? 0,
      maxGauge: json['maxGauge']?.toDouble() ?? 0,
      minSpacing: json['minSpacing']?.toDouble() ?? 0,
      maxSpacing: json['maxSpacing']?.toDouble() ?? 0,
      defaultCrossBonded: json['defaultCrossBonded'] ?? false,
      leftHandTileWidth: json['leftHandTileWidth']?.toDouble(),
      imageUrl: json['imageUrl'],
      datasheetUrl: json['datasheetUrl'],
    );
  }

  /// Helper method to parse material types from strings
  static MaterialType _parseMaterialType(String type) {
    switch (type.toLowerCase()) {
      case 'slate':
        return MaterialType.slate;
      case 'fibre-cement-slate':
        return MaterialType.fibreCementSlate;
      case 'interlocking-tile':
        return MaterialType.interlockingTile;
      case 'plain-tile':
        return MaterialType.plainTile;
      case 'concrete-tile':
        return MaterialType.concreteTile;
      case 'pantile':
        return MaterialType.pantile;
      default:
        return MaterialType.unknown;
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TileModel && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
