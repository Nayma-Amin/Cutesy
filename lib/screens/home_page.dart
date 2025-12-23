import 'dart:typed_data';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shop_cutesy/main.dart';
import 'package:shop_cutesy/screens/auth/sign_up.dart';
import 'package:shop_cutesy/screens/cart_page.dart';
import 'package:shop_cutesy/screens/management.dart';
import 'package:shop_cutesy/screens/coupon_page.dart';
import 'package:shop_cutesy/screens/product_page.dart';
import 'package:shop_cutesy/screens/profile_page.dart';
import 'package:shop_cutesy/screens/services/authentication.dart';
import 'package:shop_cutesy/screens/terms_conditions.dart';
import 'package:shop_cutesy/widgets/bottom_navigation.dart';
import 'package:shop_cutesy/widgets/menu_drop.dart';
import 'package:shop_cutesy/widgets/sliding_text.dart';
import 'package:shop_cutesy/widgets/top_bar.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class ProductItem {
  final String id;
  final String title;
  final String tag;
  final String price;
  final String imageBase64;
  final int categoryCount;

  ProductItem({
    required this.id,
    required this.title,
    required this.tag,
    required this.price,
    required this.imageBase64,
    required this.categoryCount,
  });

  factory ProductItem.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    final List categories = data['categories'] ?? [];

    return ProductItem(
      id: doc.id,
      title: data['title'] ?? '',
      tag: data['tag'] ?? '',
      price: data['price'] ?? '',
      imageBase64: (data['images'] != null && data['images'].isNotEmpty)
          ? data['images'][0]
          : '',
      categoryCount: categories.length,
    );
  }
}

class _HomePageState extends State<HomePage> with RouteAware {
  int bottomIndex = 0;
  String slidingMessage = "";

  final TextEditingController searchController = TextEditingController();
  List<String> searchSuggestions = [];
  String searchQuery = "";

  Map<String, int> tagDiscountMap = {};
  int? allDiscountPercentage;

  List<String> filters = ['All'];

  late String filterSelected;

  List<ProductItem> get filteredProducts {
    List<ProductItem> result = allProducts;

    if (filterSelected != 'All') {
      result = result.where((p) => p.tag == filterSelected).toList();
    }

    if (searchQuery.isNotEmpty) {
      result = result
          .where(
            (p) =>
                p.title.toLowerCase().contains(searchQuery) ||
                p.tag.toLowerCase().contains(searchQuery),
          )
          .toList();
    }

    return result;
  }

  List<ProductItem> allProducts = [];
  bool loadingProducts = true;

  Future<void> loadProducts() async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('products')
          .get();

      final Set<String> dynamicTags = {};

      allProducts = snap.docs.map((doc) {
        final item = ProductItem.fromFirestore(doc);
        if (item.tag.isNotEmpty) {
          dynamicTags.add(item.tag);
        }
        return item;
      }).toList();

      filters = ['All', ...dynamicTags.toList()..sort()];
    } catch (e) {
      print("PRODUCT FETCH ERROR: $e");
    }

    setState(() {
      loadingProducts = false;
    });
  }

  String username = "";
  String userRole = "user";
  bool _animate = false;
  bool menuVisible = false;
  Set<String> favouriteIds = {};

  Future<void> _loadFavourites() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final snap = await FirebaseFirestore.instance
        .collection('favourites')
        .where('userId', isEqualTo: user.uid)
        .get();

    setState(() {
      favouriteIds = snap.docs.map((d) => d['productId'].toString()).toSet();
    });
  }

  Future<void> _toggleFavouriteHome(
    String productId,
    String productTitle,
  ) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final favRef = FirebaseFirestore.instance.collection('favourites');

    if (favouriteIds.contains(productId)) {
      final snap = await favRef
          .where('userId', isEqualTo: user.uid)
          .where('productId', isEqualTo: productId)
          .get();

      for (var d in snap.docs) {
        await d.reference.delete();
      }

      setState(() {
        favouriteIds.remove(productId);
      });
    } else {
      await favRef.add({
        'userId': user.uid,
        'productId': productId,
        'productTitle': productTitle,
        'time': FieldValue.serverTimestamp(),
      });

      setState(() {
        favouriteIds.add(productId);
      });
    }
  }

  Future<void> loadSlidingMessage() async {
    final now = Timestamp.now();

    final snap = await FirebaseFirestore.instance
        .collection('discounts')
        .where('start_at', isLessThanOrEqualTo: now)
        .where('end_at', isGreaterThan: now)
        .get();

    setState(() {
      if (snap.docs.isEmpty) {
        slidingMessage =
            "Welcome to Cutesy $username! Order your favourites and stay connected with us.";
        return;
      }

      final best = snap.docs
          .map((d) => d.data())
          .reduce((a, b) => a['percentage'] > b['percentage'] ? a : b);

      final int percentage = best['percentage'];
      final List tags = List.from(best['tags']);
      final DateTime endDate = (best['end_at'] as Timestamp).toDate();

      final dateText = "${endDate.day} ${_monthName(endDate.month)}";

      slidingMessage = tags.contains("ALL")
          ? "Welcome to Cutesy $username! Enjoy upto $percentage% sale on all products till $dateText!"
          : "Welcome to Cutesy $username! Enjoy upto $percentage% sale on specific products till $dateText!";
    });
  }

  String _monthName(int m) {
    const months = [
      "January",
      "February",
      "March",
      "April",
      "May",
      "June",
      "July",
      "August",
      "September",
      "October",
      "November",
      "December",
    ];
    return months[m - 1];
  }

  void _updateSearch(String value) {
    searchQuery = value.trim().toLowerCase();

    if (searchQuery.isEmpty) {
      searchSuggestions.clear();
      setState(() {});
      return;
    }

    final matches = allProducts.where(
      (p) =>
          p.title.toLowerCase().contains(searchQuery) ||
          p.tag.toLowerCase().contains(searchQuery),
    );

    searchSuggestions = matches.map((p) => p.title).toSet().take(6).toList();

    setState(() {});
  }

  Future<void> loadDiscountsForProducts() async {
    final now = Timestamp.now();

    final snap = await FirebaseFirestore.instance
        .collection('discounts')
        .where('start_at', isLessThanOrEqualTo: now)
        .where('end_at', isGreaterThan: now)
        .get();

    tagDiscountMap.clear();
    allDiscountPercentage = null;

    for (final doc in snap.docs) {
      final data = doc.data();
      final int percentage = data['percentage'];
      final List tags = List.from(data['tags']);

      if (tags.contains("ALL")) {
        allDiscountPercentage = percentage;
      } else {
        for (final tag in tags) {
          tagDiscountMap[tag] = percentage;
        }
      }
    }
  }

  @override
  void initState() {
    super.initState();

    FirebaseAuth.instance.authStateChanges().listen((user) async {
      await loadUser();
      await loadProducts();

      if (user != null) {
        await _loadFavourites();
        await loadSlidingMessage();
        await loadDiscountsForProducts();
      }

      setState(() {});
    });

    filterSelected = filters[0];
  }

  Future<void> loadUser() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      username = "";
      userRole = "user";
      setState(() => _animate = false);
      return;
    }

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser.uid)
        .get();

    username = doc['name'] ?? "";
    userRole = doc['role'] ?? "user";

    await Future.delayed(const Duration(milliseconds: 400));
    setState(() => _animate = true);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)! as PageRoute);
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    setState(() {
      bottomIndex = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    const border = OutlineInputBorder(
      borderSide: BorderSide(color: Color(0xFFC9C7C7)),
      borderRadius: BorderRadius.horizontal(left: Radius.circular(40)),
    );

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: const Color(0xFFFDF1F5),
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TopBar(
                    onMenuTap: () {
                      setState(() {
                        menuVisible = !menuVisible;
                      });
                    },
                  ),

                  if (AuthService().isLoggedIn)
                    Center(
                      child: AnimatedOpacity(
                        opacity: _animate ? 1 : 0,
                        duration: const Duration(milliseconds: 600),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 5,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SlidingText(text: slidingMessage, speed: 30),
                            ],
                          ),
                        ),
                      ),
                    )
                  else
                    const SizedBox.shrink(),

                  Row(
                    children: [
                      Padding(
                        padding: EdgeInsets.all(15),
                        child: Text(
                          'Shop at\nCutesy!',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 40,
                          ),
                        ),
                      ),
                      Expanded(
                        child: TextField(
                          controller: searchController,
                          onChanged: _updateSearch,
                          onSubmitted: (value) {
                            searchQuery = value.toLowerCase();
                            searchSuggestions.clear();
                            setState(() {});
                          },
                          decoration: InputDecoration(
                            hintText: 'search',
                            prefixIcon: const Icon(Icons.search),
                            border: border,
                            enabledBorder: border,
                            focusedBorder: border,
                          ),
                        ),
                      ),
                    ],
                  ),

                  if (searchSuggestions.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Container(
                        constraints: const BoxConstraints(maxHeight: 200),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: searchSuggestions.length,
                          itemBuilder: (context, index) {
                            final s = searchSuggestions[index];
                            return ListTile(
                              dense: true,
                              title: Text(s),
                              onTap: () {
                                searchController.text = s;
                                searchQuery = s.toLowerCase();
                                searchSuggestions.clear();
                                setState(() {});
                              },
                            );
                          },
                        ),
                      ),
                    ),

                  SizedBox(
                    height: 70,
                    child: ListView.builder(
                      itemCount: filters.length,
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      itemBuilder: (context, index) {
                        final filter = filters[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 5),
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                filterSelected = filter;
                              });
                            },
                            child: Chip(
                              backgroundColor: filterSelected == filter
                                  ? const Color(0xFFB564F7)
                                  : const Color(0xFFF1D9FB),
                              label: Text(
                                filter,
                                style: const TextStyle(color: Colors.black),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 15,
                                vertical: 8,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.6,
                    child: loadingProducts
                        ? const SizedBox.shrink()
                        : filteredProducts.isEmpty
                        ? const Center(
                            child: Text(
                              "No products found!",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey,
                              ),
                            ),
                          )
                        : GridView.builder(
                            padding: const EdgeInsets.all(15),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  mainAxisSpacing: 20,
                                  crossAxisSpacing: 15,
                                  childAspectRatio: 0.72,
                                ),
                            itemCount: filteredProducts.length,
                            itemBuilder: (context, index) {
                              final product = filteredProducts[index];

                              final int originalPrice =
                                  int.tryParse(product.price) ?? 0;

                              final int? discountPercent =
                                  tagDiscountMap[product.tag] ??
                                  allDiscountPercentage;

                              final int discountedPrice =
                                  discountPercent != null
                                  ? (originalPrice -
                                        (originalPrice *
                                            discountPercent ~/
                                            100))
                                  : originalPrice;

                              Uint8List? imageBytes;
                              if (product.imageBase64.isNotEmpty) {
                                try {
                                  imageBytes = base64Decode(
                                    product.imageBase64,
                                  );
                                } catch (e) {
                                  imageBytes = null;
                                }
                              }

                              return GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          ProductPage(productId: product.id),
                                    ),
                                  );
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(18),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.07),
                                        blurRadius: 6,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      ClipRRect(
                                        borderRadius:
                                            const BorderRadius.vertical(
                                              top: Radius.circular(18),
                                            ),
                                        child: imageBytes != null
                                            ? Image.memory(
                                                imageBytes,
                                                height: 150,
                                                width: double.infinity,
                                                fit: BoxFit.cover,
                                              )
                                            : Container(
                                                height: 150,
                                                color: Colors.grey.shade300,
                                                child: const Center(
                                                  child: Icon(
                                                    Icons.image,
                                                    size: 40,
                                                  ),
                                                ),
                                              ),
                                      ),

                                      Padding(
                                        padding: const EdgeInsets.all(8),
                                        child: Text(
                                          product.title,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),

                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            if (discountPercent != null) ...[
                                              Row(
                                                children: [
                                                  Text(
                                                    "৳$discountedPrice",
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 16,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Text(
                                                    "৳$originalPrice",
                                                    style: const TextStyle(
                                                      decoration: TextDecoration
                                                          .lineThrough,
                                                      color: Colors.grey,
                                                      fontSize: 13,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Text(
                                                    "-$discountPercent%",
                                                    style: const TextStyle(
                                                      color: Colors.green,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 13,
                                                    ),
                                                  ),
                                                  const Spacer(),
                                                  GestureDetector(
                                                    onTap: () =>
                                                        _toggleFavouriteHome(
                                                          product.id,
                                                          product.title,
                                                        ),
                                                    child: Icon(
                                                      favouriteIds.contains(
                                                            product.id,
                                                          )
                                                          ? Icons.favorite
                                                          : Icons
                                                                .favorite_border,
                                                      color: const Color(
                                                        0xFFB564F7,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ] else ...[
                                              Row(
                                                children: [
                                                  Text(
                                                    "৳$originalPrice",
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 16,
                                                    ),
                                                  ),
                                                  const Spacer(),
                                                  GestureDetector(
                                                    onTap: () =>
                                                        _toggleFavouriteHome(
                                                          product.id,
                                                          product.title,
                                                        ),
                                                    child: Icon(
                                                      favouriteIds.contains(
                                                            product.id,
                                                          )
                                                          ? Icons.favorite
                                                          : Icons
                                                                .favorite_border,
                                                      color: const Color(
                                                        0xFFB564F7,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),

                                      if (product.categoryCount > 0)
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            top: 4,
                                          ),
                                          child: Center(
                                            child: Text(
                                              "${product.categoryCount} Options",
                                              style: const TextStyle(
                                                fontSize: 14,
                                                color: Colors.purple,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),

            if (menuVisible)
              Positioned(
                top: 70,
                right: 10,
                left: 10,
                child: DropMenu(
                  isVisible: menuVisible,
                  onItemTap: (value) {
                    setState(() => menuVisible = false);

                    if (value == "Management") {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ManagementPage(),
                        ),
                      );
                    }
                    if (value == "Terms and Conditions") {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const TermsManage(),
                        ),
                      );
                    }
                  },

                  userRole: userRole,
                ),
              ),
          ],
        ),
      ),

      bottomNavigationBar: BottomNavBar(
        currentIndex: bottomIndex,
        onTap: (index) {
          setState(() {
            bottomIndex = index;
          });

          if (index == 0) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const HomePage()),
            );
          }

          if (index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CouponPage()),
            );
          }

          if (index == 2) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CartPage()),
            );
          }

          if (index == 3) {
            final user = FirebaseAuth.instance.currentUser;

            if (user != null) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfilePage()),
              );
            } else {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SignupPage()),
              );
            }
          }
        },
      ),
    );
  }
}
