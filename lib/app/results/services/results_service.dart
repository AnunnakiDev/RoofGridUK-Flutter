import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:roofgrid_uk/app/results/models/saved_result.dart';

class ResultsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  /// Get a stream of saved results for a user
  Stream<List<SavedResult>> getSavedResults(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('savedResults')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => SavedResult.fromFirestore(doc))
            .toList());
  }
  
  /// Search saved results by project name
  Future<List<SavedResult>> searchResults(String userId, String query) async {
    query = query.toLowerCase();
    
    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('savedResults')
        .orderBy('timestamp', descending: true)
        .get();
        
    return snapshot.docs
        .map((doc) => SavedResult.fromFirestore(doc))
        .where((result) => 
            result.projectName.toLowerCase().contains(query) ||
            _containsInInputLabels(result.inputs, query))
        .toList();
  }
  
  /// Check if any input label contains the search query
  bool _containsInInputLabels(Map<String, dynamic> inputs, String query) {
    // Check in rafterHeights
    if (inputs.containsKey('rafterHeights')) {
      final rafterHeights = inputs['rafterHeights'] as List;
      for (var rafter in rafterHeights) {
        if (rafter is Map && 
            rafter.containsKey('label') &&
            rafter['label'].toString().toLowerCase().contains(query)) {
          return true;
        }
      }
    }
    
    // Check in widths
    if (inputs.containsKey('widths')) {
      final widths = inputs['widths'] as List;
      for (var width in widths) {
        if (width is Map && 
            width.containsKey('label') && 
            width['label'].toString().toLowerCase().contains(query)) {
          return true;
        }
      }
    }
    
    return false;
  }
  
  /// Save a new result
  Future<bool> saveResult(SavedResult result) async {
    try {
      await _firestore
          .collection('users')
          .doc(result.userId)
          .collection('savedResults')
          .doc(result.id)
          .set(result.toFirestore());
      return true;
    } catch (e) {
      print('Error saving result: $e');
      return false;
    }
  }
  
  /// Update an existing result
  Future<bool> updateResult(SavedResult result) async {
    try {
      await _firestore
          .collection('users')
          .doc(result.userId)
          .collection('savedResults')
          .doc(result.id)
          .update(result.toFirestore());
      return true;
    } catch (e) {
      print('Error updating result: $e');
      return false;
    }
  }
  
  /// Delete a result
  Future<bool> deleteResult(String userId, String resultId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('savedResults')
          .doc(resultId)
          .delete();
      return true;
    } catch (e) {
      print('Error deleting result: $e');
      return false;
    }
  }
  
  /// Rename a calculation input (rafter or width)
  Future<bool> renameInput(SavedResult result, String inputType, int index, String newLabel) async {
    try {
      final inputs = Map<String, dynamic>.from(result.inputs);
      
      if (inputType == 'rafterHeights' && inputs.containsKey('rafterHeights')) {
        final List<dynamic> rafters = List.from(inputs['rafterHeights']);
        if (index < rafters.length) {
          rafters[index] = {
            ...rafters[index] as Map<String, dynamic>,
            'label': newLabel
          };
          inputs['rafterHeights'] = rafters;
        }
      } else if (inputType == 'widths' && inputs.containsKey('widths')) {
        final List<dynamic> widths = List.from(inputs['widths']);
        if (index < widths.length) {
          widths[index] = {
            ...widths[index] as Map<String, dynamic>,
            'label': newLabel
          };
          inputs['widths'] = widths;
        }
      }
      
      final updatedResult = result.copyWith(inputs: inputs);
      return await updateResult(updatedResult);
    } catch (e) {
      print('Error renaming input: $e');
      return false;
    }
  }
  
  /// Generate a PDF export of the result
  Future<String?> exportResultAsPdf(SavedResult result) async {
    // TODO: Implement PDF export functionality
    // For this implementation, we'll return null as this requires additional PDF generation library
    return null;
  }
}
