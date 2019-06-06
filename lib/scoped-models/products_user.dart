import 'package:flutter_course/models/product.dart';
import 'package:flutter_course/models/user.dart';
import 'package:http/http.dart';
import 'package:scoped_model/scoped_model.dart';
import '../models/auth.dart';

import 'package:http/http.dart' as http;
import 'package:rxdart/subjects.dart';
import 'dart:convert';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

class ProductsUserModel extends Model {
  List<Product> _products = [];
  User _authenticatedUser;

  String _selProductId;

  bool _isLoading = false;
  // notifyListeners();
}

/**
 * Products model class
 */

class ProductsModel extends ProductsUserModel {
  bool _showFavorites = false;

  List<Product> get allProducts {
    return List.from(_products);
  }

  List<Product> get displayedProduct {
    return (_showFavorites)
        ? _products.where((Product product) => product.isFavorite).toList()
        : List.from(_products);
  }

  int get selectedProductIndex {
    return _products.indexWhere((Product product) {
      return product.id == _selProductId;
    });
  }

  String get selectedProductId {
    return _selProductId;
  }

  bool get displayMode {
    return _showFavorites;
  }

  Product get selectedProduct {
    return (_selProductId == null)
        ? null
        : _products.firstWhere((Product product) {
            return product.id == _selProductId;
          });
  }

  Future<bool> addProduct(
      String title, String description, String image, double price) async {
    try {
      _isLoading = true;
      final Map<String, dynamic> productData = {
        'title': title,
        'description': description,
        'price': price,
        'userId': _authenticatedUser.id,
        'userEmail': _authenticatedUser.email,
        'image':
            'https://www.dccomics.com/sites/default/files/styles/comics320x485/public/Char_Thumb_Batman_20190116_5c3fc4b40fae42.85141247.jpg?itok=_Or1JrO2'
      };
      final http.Response response = await http.post(
          'https://acoustic-realm-230117.firebaseio.com/products.json?auth=${_authenticatedUser.token}',
          body: json.encode(productData));
      if (response.statusCode != 200 && response.statusCode != 201) {
        _isLoading = false;
        notifyListeners();
        return false;
      }
      _isLoading = false;
      final Map<String, dynamic> responseData = json.decode(response.body);
      final Product product = Product(
          id: responseData['name'],
          title: title,
          description: description,
          image: image,
          price: price,
          userId: _authenticatedUser.id,
          userEmail: _authenticatedUser.email);
      _products.add(product);
      notifyListeners();
      return true;
    } catch (error) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateProduct(
      String title, String description, String image, double price) {
    _isLoading = true;
    final Map<String, dynamic> updateData = {
      'id': selectedProduct.id,
      'title': title,
      'image':
          'https://www.dccomics.com/sites/default/files/styles/comics320x485/public/Char_Thumb_Batman_20190116_5c3fc4b40fae42.85141247.jpg?itok=_Or1JrO2',
      'price': price,
      'description': description,
      'userId': _authenticatedUser.id,
      'userEmail': _authenticatedUser.email,
    };
    return http
        .put(
            'https://acoustic-realm-230117.firebaseio.com/products/${selectedProduct.id}.json?auth=${_authenticatedUser.token}',
            body: json.encode(updateData))
        .then((Response response) {
      if (response.statusCode != 200 && response.statusCode != 201) {
        _isLoading = false;
        notifyListeners();
        return false;
      }
      _isLoading = false;
      final Product product = Product(
          id: selectedProduct.id,
          title: title,
          description: description,
          image: image,
          price: price,
          userId: _authenticatedUser.id,
          userEmail: _authenticatedUser.email);
      _products[selectedProductIndex] = product;
      notifyListeners();
      return true;
    }).catchError((error) {
      _isLoading = false;
      notifyListeners();
      return false;
    });
  }

  void toggleStatus() async {
    print(
        '[DEBUG] https://acoustic-realm-230117.firebaseio.com/products/${selectedProduct.id}/wishlistUsers/${_authenticatedUser.id}.json?auth=${_authenticatedUser.token}');

    final bool isCurrentlyFavorite = _products[selectedProductIndex].isFavorite;
    final bool newFavoriteStatus = !isCurrentlyFavorite;
    final Product updatedProduct = Product(
        id: selectedProduct.id,
        title: selectedProduct.title,
        description: selectedProduct.description,
        image: selectedProduct.image,
        userEmail: selectedProduct.userEmail,
        userId: selectedProduct.userId,
        price: selectedProduct.price,
        isFavorite: newFavoriteStatus);
    _products[selectedProductIndex] = updatedProduct;
    notifyListeners();
    http.Response response;
    if (newFavoriteStatus) {
      response = await http.put(
          'https://acoustic-realm-230117.firebaseio.com/products/${selectedProduct.id}/wishlistUsers/${_authenticatedUser.id}.json?auth=${_authenticatedUser.token}',
          body: json.encode(true));
      if (response.statusCode != 200 && response.statusCode != 201) {
        final Product updatedProduct = Product(
            id: selectedProduct.id,
            title: selectedProduct.title,
            description: selectedProduct.description,
            image: selectedProduct.image,
            userEmail: selectedProduct.userEmail,
            userId: selectedProduct.userId,
            price: selectedProduct.price,
            isFavorite: newFavoriteStatus);
        _products[selectedProductIndex] = updatedProduct;
      }
    } else {
      response = await http.delete(
          'https://acoustic-realm-230117.firebaseio.com/products/${selectedProduct.id}/wishlistUsers/${_authenticatedUser.id}.json?auth=${_authenticatedUser.token}');
      if (response.statusCode != 200 && response.statusCode != 201) {
        final Product updatedProduct = Product(
            id: selectedProduct.id,
            title: selectedProduct.title,
            description: selectedProduct.description,
            image: selectedProduct.image,
            userEmail: selectedProduct.userEmail,
            userId: selectedProduct.userId,
            price: selectedProduct.price,
            isFavorite: newFavoriteStatus);
        _products[selectedProductIndex] = updatedProduct;
      }
    }
    notifyListeners();
  }

  Future<bool> deleteProduct() {
    _isLoading = true;
    final String deletedProduct = selectedProduct.id;
    _products.removeAt(selectedProductIndex);
    _selProductId = null;
    notifyListeners();
    return http
        .delete(
            'https://acoustic-realm-230117.firebaseio.com/products/${deletedProduct}.json?auth=${_authenticatedUser.token}')
        .then((Response response) {
      if (response.statusCode != 200 && response.statusCode != 201) {
        _isLoading = false;
        notifyListeners();
        return false;
      }
      _isLoading = false;
      notifyListeners();
      return true;
    }).catchError((error) {
      _isLoading = false;
      notifyListeners();
      return false;
    });
  }

  void selectProduct(String productId) {
    _selProductId = productId;
  }

  void toggleDisplayMode() {
    _showFavorites = !_showFavorites;
    notifyListeners();
  }

  Future<bool> fetchProducts() {
    _isLoading = true;
    return http
        .get(
            'https://acoustic-realm-230117.firebaseio.com/products.json?auth=${_authenticatedUser.token}')
        .then((http.Response response) {
      if (response.statusCode != 200 && response.statusCode != 201) {
        _isLoading = false;
        notifyListeners();
        return false;
      }
      _isLoading = false;
      final Map<String, dynamic> productListData = json.decode(response.body);
      if (productListData == null) {
        _isLoading = false;
        notifyListeners();
        return false;
      }
      final List<Product> fetchedProductList = [];

      productListData.forEach((String productId, dynamic productData) {
        final Product product = Product(
            id: productId,
            title: productData['title'],
            description: productData['description'],
            image: productData['image'],
            price: productData['price'],
            userEmail: productData['userEmail'],
            userId: productData['userId'].toString());
        fetchedProductList.add(product);
      });
      _products = fetchedProductList;
      notifyListeners();
      _selProductId = null;
    }).catchError((error) {
      _isLoading = false;
      notifyListeners();
      return false;
    });
  }
}

/**
 * User Model Class
 */

class UserModel extends ProductsUserModel {
  Timer _authTimer;
  PublishSubject<bool> _userSubject = PublishSubject();
  PublishSubject<bool> get userSubject {
    return _userSubject;
  }

  User get user {
    return _authenticatedUser;
  }

  Future<Map<String, dynamic>> authenticate(String email, String password,
      [AuthMode authMode = AuthMode.Login]) async {
    _isLoading = true;
    notifyListeners();
    final Map<String, dynamic> authData = {
      'email': email,
      'password': password
    };
    http.Response response;
    if (authMode == AuthMode.Login) {
      response = await http.post(
          'https://www.googleapis.com/identitytoolkit/v3/relyingparty/verifyPassword?key=AIzaSyBdurrg_AHmrd1M3WWpC3nCoRtqWKWHV2U',
          body: json.encode(authData),
          headers: {'Content-Type': 'application/json'});
    } else {
      response = await http.post(
          'https://www.googleapis.com/identitytoolkit/v3/relyingparty/signupNewUser?key=AIzaSyBdurrg_AHmrd1M3WWpC3nCoRtqWKWHV2U',
          body: json.encode(authData),
          headers: {'Content-Type': 'application/json'});
    }
    final Map<String, dynamic> responseData = json.decode(response.body);
    print(responseData);
    bool hasError = true;
    String message = 'Something went wrong';
    if (responseData.containsKey('idToken')) {
      hasError = false;
      message = 'Authentication Successful';
      _authenticatedUser = User(
          id: responseData['localId'],
          email: email,
          token: responseData['idToken']);
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final DateTime now = DateTime.now();

      final DateTime expiryTime = now.add(Duration(seconds: 5));
      // now.add(Duration(seconds: int.parse(responseData['expiresIn'])));
      prefs.setString('token', responseData['idToken']);
      prefs.setString('userEmail', email);
      prefs.setString('userId', responseData['localId']);
      prefs.setString('expiryTime', expiryTime.toIso8601String());
      // setAuthTimeout(int.parse(responseData['expiresIn']));
      setAuthTimeout(5);
    } else {
      if (responseData['error']['message'] == 'EMAIL_EXISTS')
        message = 'Email already exists';
      else if (responseData['error']['message'] == 'EMAIL_NOT_FOUND')
        message = 'Email not found';
      else if (responseData['error']['message'] == 'INVALID_PASSWORD')
        message = 'Password invalid';
      else if (responseData['error']['message'] == 'UESR_DISABLED')
        message = 'The user is disabled by admin';
    }
    print(json.decode(response.body));
    _isLoading = false;
    notifyListeners();
    return {'success': !hasError, 'message': message};
  }

  autoAuthenticate() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String token = prefs.getString('token');
    final String expiryTimeString = prefs.getString('expiryTime');
    if (token != null) {
      final DateTime now = DateTime.now();
      final parsedExpiryTime = DateTime.parse(expiryTimeString);
      if (parsedExpiryTime.isBefore(now)) {
        _authenticatedUser = null;
        notifyListeners();
        return;
      }
      final String userEmail = prefs.getString('userEmail');
      final String userId = prefs.getString('userId');
      _authenticatedUser = User(id: userId, email: userEmail, token: token);
      _userSubject.add(true);
      final tokenLifeSpan = parsedExpiryTime.difference(now).inSeconds;
      setAuthTimeout(tokenLifeSpan);
      notifyListeners();
    }
  }

  logout() async {
    _authenticatedUser = null;
    _authTimer.cancel();
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.remove('token');
    prefs.remove('userEmail');
    prefs.remove('userId');
    notifyListeners();
  }

  setAuthTimeout(int time) {
    _authTimer = Timer(Duration(seconds: time), () {
      logout();
      _userSubject.add(false);
    });
  }
}

class UtilityModel extends ProductsUserModel {
  bool get isLoading {
    return _isLoading;
  }
}
