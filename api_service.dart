import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'http://127.0.0.1:3001/api';
  static Map<String, String> get headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // ==================== CORE HTTP METHODS ====================
  static Future<List<Map<String, dynamic>>> getData(String endpoint) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/$endpoint'),
        headers: headers,
      ).timeout(const Duration(seconds: 30));
      
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data);
      }
      return [];
    } catch (e) {
      print('Error in getData: $e');
      return [];
    }
  }

  static Future<bool> postData(String endpoint, Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/$endpoint'),
        headers: headers,
        body: jsonEncode(data),
      ).timeout(const Duration(seconds: 30));
      
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('Error in postData: $e');
      return false;
    }
  }

  static Future<bool> putData(String endpoint, int id, Map<String, dynamic> data) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/$endpoint/$id'),
        headers: headers,
        body: jsonEncode(data),
      ).timeout(const Duration(seconds: 30));
      
      return response.statusCode == 200;
    } catch (e) {
      print('Error in putData: $e');
      return false;
    }
  }

  static Future<bool> deleteData(String endpoint, int id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/$endpoint/$id'),
        headers: headers,
      ).timeout(const Duration(seconds: 30));
      
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      print('Error in deleteData: $e');
      return false;
    }
  }

  // ==================== CATEGORY METHODS ====================
  static Future<List<Map<String, dynamic>>> getCategories() async {
    return await getData('categories');
  }

  static Future<bool> addCategory(Map<String, dynamic> category) async {
    if (category['name'] == null || category['name'].toString().trim().isEmpty) {
      return false;
    }
    return await postData('categories', category);
  }

  static Future<bool> updateCategory(int id, Map<String, dynamic> category) async {
    return await putData('categories', id, category);
  }

  static Future<bool> deleteCategory(int id) async {
    return await deleteData('categories', id);
  }

  // ==================== BOOK METHODS ====================
  static Future<List<Map<String, dynamic>>> getBooks() async {
    return await getData('books');
  }

  static Future<bool> addBook(Map<String, dynamic> book) async {
    if (book['title'] == null || book['title'].toString().trim().isEmpty) {
      return false;
    }
    return await postData('books', book);
  }

  static Future<bool> updateBook(int id, Map<String, dynamic> book) async {
    return await putData('books', id, book);
  }

  static Future<bool> deleteBook(int id) async {
    return await deleteData('books', id);
  }

  // ==================== MEMBER METHODS ====================
  static Future<List<Map<String, dynamic>>> getMembers() async {
    return await getData('members');
  }

  static Future<bool> addMember(Map<String, dynamic> member) async {
    if (member['name'] == null || member['name'].toString().trim().isEmpty) {
      return false;
    }
    return await postData('members', member);
  }

  static Future<bool> updateMember(int id, Map<String, dynamic> member) async {
    return await putData('members', id, member);
  }

  static Future<bool> deleteMember(int id) async {
    return await deleteData('members', id);
  }

  // ==================== BORROWING METHODS ====================
  static Future<List<Map<String, dynamic>>> getBorrowings() async {
    return await getData('borrowings');
  }

  static Future<bool> addBorrowing(Map<String, dynamic> borrowing) async {
    return await postData('borrowings', borrowing);
  }

  static Future<bool> updateBorrowing(int id, Map<String, dynamic> borrowing) async {
    return await putData('borrowings', id, borrowing);
  }

  static Future<bool> deleteBorrowing(int id) async {
    return await deleteData('borrowings', id);
  }

  // ==================== UTILITY METHODS ====================
  static Future<bool> testConnection() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/health'),
        headers: headers,
      ).timeout(const Duration(seconds: 10));
      
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}