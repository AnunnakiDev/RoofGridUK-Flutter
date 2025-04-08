import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:csv/csv.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roofgrid_uk/app/auth/models/user_model.dart';
import 'package:roofgrid_uk/app/tiles/models/tile_model.dart';

/// Service for managing roof tiles
class TileService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Load tiles from the CSV file in assets
  Future<List<TileModel>> loadTilesFromCsv(String userId) async {
    try {
      // Load the CSV file from assets
      final String csvString =
          await rootBundle.loadString('assets/TileDataCSV.csv');

      // Parse the CSV data
      List<List<dynamic>> csvTable =
          const CsvToListConverter().convert(csvString);

      // Extract headers and data
      List<String> headers =
          csvTable[0].map<String>((item) => item.toString()).toList();
      List<Map<String, dynamic>> dataList = [];

      // Convert CSV rows to maps
      for (int i = 1; i < csvTable.length; i++) {
        Map<String, dynamic> row = {};
        for (int j = 0; j < headers.length && j < csvTable[i].length; j++) {
          row[headers[j]] = csvTable[i][j].toString();
        }
        dataList.add(row);
      }

      // Convert maps to TileModels
      return dataList
          .map((row) => TileModel.fromCsv(row, userId: userId))
          .toList();
    } catch (e) {
      print('Error loading tiles from CSV: $e');
      return [];
    }
  }

  /// Get user's custom tiles from Firestore
  Future<List<TileModel>> getUserTiles(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('tiles')
          .where('createdById', isEqualTo: userId)
          .get();

      return snapshot.docs
          .map((doc) => TileModel.fromJson(doc.data()))
          .toList();
    } catch (e) {
      print('Error getting user tiles: $e');
      return [];
    }
  }

  /// Get public and approved tiles from Firestore (default tiles)
  Future<List<TileModel>> getPublicTiles() async {
    try {
      final snapshot = await _firestore
          .collection('tiles')
          .where('isPublic', isEqualTo: true)
          .where('isApproved', isEqualTo: true)
          .get();

      return snapshot.docs
          .map((doc) => TileModel.fromJson(doc.data()))
          .toList();
    } catch (e) {
      print('Error getting public tiles: $e');
      return [];
    }
  }

  /// Get tiles pending approval (for admin users only)
  Future<List<TileModel>> getTilesPendingApproval() async {
    try {
      final snapshot = await _firestore
          .collection('tiles')
          .where('isPublic', isEqualTo: true)
          .where('isApproved', isEqualTo: false)
          .get();

      return snapshot.docs
          .map((doc) => TileModel.fromJson(doc.data()))
          .toList();
    } catch (e) {
      print('Error getting tiles pending approval: $e');
      return [];
    }
  }

  /// Save a tile to Firestore - respects permission level
  Future<bool> saveTile(TileModel tile, UserRole userRole) async {
    try {
      // Free users cannot save tiles
      if (userRole == UserRole.free) {
        return false;
      }

      await _firestore.collection('tiles').doc(tile.id).set(tile.toJson());

      return true;
    } catch (e) {
      print('Error saving tile: $e');
      return false;
    }
  }

  /// Save a copy of a public tile as user's personal tile (for Pro users)
  Future<bool> savePublicTileAsCopy(
      TileModel originalTile, String userId) async {
    try {
      // Create a copy of the tile with a new ID and set it as the user's personal tile
      final personalTile = originalTile.copyWith(
        id: 'tile_${DateTime.now().millisecondsSinceEpoch}',
        isPublic: false,
        isApproved: true,
        createdById: userId,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _firestore
          .collection('tiles')
          .doc(personalTile.id)
          .set(personalTile.toJson());

      return true;
    } catch (e) {
      print('Error saving public tile as copy: $e');
      return false;
    }
  }

  /// Submit a tile for admin approval
  Future<bool> submitTileForApproval(TileModel tile) async {
    try {
      final submittedTile = tile.copyWith(
        isPublic: true,
        isApproved: false,
        updatedAt: DateTime.now(),
      );

      await _firestore
          .collection('tiles')
          .doc(submittedTile.id)
          .update(submittedTile.toJson());

      return true;
    } catch (e) {
      print('Error submitting tile for approval: $e');
      return false;
    }
  }

  /// Approve a submitted tile (admin only)
  Future<bool> approveTile(String tileId) async {
    try {
      await _firestore.collection('tiles').doc(tileId).update({
        'isApproved': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      print('Error approving tile: $e');
      return false;
    }
  }

  /// Update a tile in Firestore
  Future<bool> updateTile(TileModel tile, UserRole userRole) async {
    try {
      // Check permissions
      if (userRole == UserRole.free) {
        return false;
      }

      // For non-admin users, ensure they can only update their own tiles
      if (userRole != UserRole.admin) {
        final tileDoc = await _firestore.collection('tiles').doc(tile.id).get();
        if (tileDoc.exists) {
          final existingTile = TileModel.fromJson(tileDoc.data()!);
          if (existingTile.isPublic &&
              existingTile.isApproved &&
              existingTile.createdById != tile.createdById) {
            // Non-admin users can't modify default tiles directly
            return false;
          }
        }
      }

      await _firestore
          .collection('tiles')
          .doc(tile.id)
          .update(tile.copyWith(updatedAt: DateTime.now()).toJson());

      return true;
    } catch (e) {
      print('Error updating tile: $e');
      return false;
    }
  }

  /// Delete a tile from Firestore
  Future<bool> deleteTile(
      String tileId, UserRole userRole, String userId) async {
    try {
      // Free users can't delete tiles
      if (userRole == UserRole.free) {
        return false;
      }

      // For non-admin users, ensure they can only delete their own tiles
      if (userRole != UserRole.admin) {
        final tileDoc = await _firestore.collection('tiles').doc(tileId).get();
        if (tileDoc.exists) {
          final existingTile = TileModel.fromJson(tileDoc.data()!);
          if (existingTile.isPublic &&
              existingTile.isApproved &&
              existingTile.createdById != userId) {
            // Non-admin users can't delete public/default tiles
            return false;
          }
        }
      }

      await _firestore.collection('tiles').doc(tileId).delete();

      return true;
    } catch (e) {
      print('Error deleting tile: $e');
      return false;
    }
  }

  /// Import tiles from CSV file (admin only)
  Future<List<TileModel>> importTilesFromCsv(
      File csvFile, String adminUserId) async {
    try {
      final String csvContent = await csvFile.readAsString();

      // Parse the CSV data
      List<List<dynamic>> csvTable =
          const CsvToListConverter().convert(csvContent);

      // Extract headers and data
      List<String> headers =
          csvTable[0].map<String>((item) => item.toString()).toList();
      List<Map<String, dynamic>> dataList = [];

      // Convert CSV rows to maps
      for (int i = 1; i < csvTable.length; i++) {
        Map<String, dynamic> row = {};
        for (int j = 0; j < headers.length && j < csvTable[i].length; j++) {
          row[headers[j]] = csvTable[i][j].toString();
        }
        dataList.add(row);
      }

      // Convert maps to TileModels
      final tiles = dataList.map((row) {
        final tile = TileModel.fromCsv(row, userId: adminUserId);
        return tile;
      }).toList();

      // Save all tiles to Firestore
      for (var tile in tiles) {
        await _firestore.collection('tiles').doc(tile.id).set(tile.toJson());
      }

      return tiles;
    } catch (e) {
      print('Error importing tiles from CSV: $e');
      return [];
    }
  }

  /// Check if calculation results can be saved based on user role
  bool canSaveResults(UserRole userRole) {
    return userRole == UserRole.pro || userRole == UserRole.admin;
  }

  /// Check if user needs to be prompted to upgrade (for free users)
  bool shouldPromptToUpgrade(UserRole userRole) {
    return userRole == UserRole.free;
  }
}

/// Provider for tile service
final tileServiceProvider = Provider<TileService>((ref) {
  return TileService();
});

/// Provider for user's tiles
final userTilesProvider =
    FutureProvider.family<List<TileModel>, String>((ref, userId) async {
  final tileService = ref.read(tileServiceProvider);
  return await tileService.getUserTiles(userId);
});

/// Provider for default/public tiles
final defaultTilesProvider = FutureProvider<List<TileModel>>((ref) async {
  final tileService = ref.read(tileServiceProvider);
  return await tileService.getPublicTiles();
});

/// Provider for tiles pending approval (admin only)
final pendingApprovalTilesProvider =
    FutureProvider<List<TileModel>>((ref) async {
  final tileService = ref.read(tileServiceProvider);
  return await tileService.getTilesPendingApproval();
});

/// Provider for all available tiles based on user permissions
final availableTilesProvider =
    FutureProvider.family<List<TileModel>, UserModel>((ref, user) async {
  final tileService = ref.read(tileServiceProvider);

  // Free users can only use default tiles but can't save them
  if (user.isFree) {
    return await tileService.getPublicTiles();
  }

  // Pro and Admin users can access both personal and default tiles
  final userTiles = await ref.watch(userTilesProvider(user.uid).future);
  final defaultTiles = await ref.watch(defaultTilesProvider.future);

  // Combine and remove duplicates
  final allTiles = [...userTiles, ...defaultTiles];
  final uniqueTiles = allTiles
      .fold<Map<String, TileModel>>({}, (map, tile) {
        if (!map.containsKey(tile.id)) {
          map[tile.id] = tile;
        }
        return map;
      })
      .values
      .toList();

  return uniqueTiles;
});
