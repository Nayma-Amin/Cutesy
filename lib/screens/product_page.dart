import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shop_cutesy/screens/management.dart';
import 'package:shop_cutesy/screens/terms_conditions.dart';
import 'package:shop_cutesy/widgets/bottom_navigation.dart';
import 'package:shop_cutesy/widgets/menu_drop.dart';
import 'package:shop_cutesy/widgets/sliding_text.dart';
import 'package:shop_cutesy/widgets/top_bar.dart';

class ProductPage extends StatefulWidget {
  final String productId;

  const ProductPage({super.key, required this.productId});

  @override
  State<ProductPage> createState() => _ProductPageState();
}

class _OptionChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _OptionChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFB564F7) : const Color(0xFFF1D9FB),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(color: selected ? Colors.white : Colors.black),
        ),
      ),
    );
  }
}

class _ProductPageState extends State<ProductPage>
    with SingleTickerProviderStateMixin {
  int bottomIndex = -1;
  int quantity = 1;
  bool isFav = false;
  String? selectedOption;

  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;

  String username = "";
  String userRole = "user";
  bool isLoggedIn = false;
  bool menuVisible = false;

  bool _animateSlidingText = false;
  String slidingBannerText = "";

  Map<String, dynamic>? productData;

  List<String> imageList = [];
  int currentImageIndex = 0;

  List<Map<String, dynamic>> reviews = [];
  int currentReviewIndex = 0;
  PageController reviewPageController = PageController();

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    Future.delayed(const Duration(seconds: 10), () {
      if (reviews.isNotEmpty && mounted) {
        int nextIndex = (currentReviewIndex + 1) % reviews.length;
        reviewPageController.animateToPage(
          nextIndex,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      }
    });

    isFav = false;
    _checkFavourite();
    _loadUser();
    _loadProduct();
    _loadReviews();
  }

  String _formatDate(Timestamp timestamp) {
    final date = timestamp.toDate();
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    final day = date.day;
    final suffix = (day >= 11 && day <= 13)
        ? 'th'
        : (day % 10 == 1)
        ? 'st'
        : (day % 10 == 2)
        ? 'nd'
        : (day % 10 == 3)
        ? 'rd'
        : 'th';

    return "$day$suffix ${months[date.month - 1]}";
  }

  void _showAddReviewDialog() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    TextEditingController reviewC = TextEditingController();
    List<String> reviewImages = [];
    String? selectedReviewOption;
    int rating = 0;

    final categories = (productData?['categories'] is List)
        ? List<String>.from(productData!['categories'])
        : [];

    showDialog(
      context: context,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> pickImage() async {
              if (reviewImages.length >= 2) return;

              final file = await ImagePicker().pickImage(
                source: ImageSource.gallery,
              );
              if (file != null) {
                final bytes = await File(file.path).readAsBytes();
                reviewImages.add(base64Encode(bytes));
                setDialogState(() {});
              }
            }

            return AlertDialog(
              backgroundColor: const Color(0xFFFDF1F5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Text("Add Review"),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: List.generate(2, (i) {
                        return GestureDetector(
                          onTap: pickImage,
                          child: Container(
                            margin: const EdgeInsets.only(right: 8),
                            width: 70,
                            height: 70,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1D9FB),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: reviewImages.length > i
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.memory(
                                      base64Decode(reviewImages[i]),
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : const Icon(Icons.add),
                          ),
                        );
                      }),
                    ),

                    const SizedBox(height: 12),

                    const Text(
                      "Select Option",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Wrap(
                      spacing: 8,
                      children: categories.map((c) {
                        return _OptionChip(
                          label: c,
                          selected: selectedReviewOption == c,
                          onTap: () {
                            setDialogState(() => selectedReviewOption = c);
                          },
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 12),

                    const Text(
                      "Rating",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Row(
                      children: List.generate(5, (i) {
                        return IconButton(
                          icon: Icon(
                            i < rating ? Icons.star : Icons.star_border,
                            color: Colors.amber,
                          ),
                          onPressed: () {
                            setDialogState(() => rating = i + 1);
                          },
                        );
                      }),
                    ),

                    TextField(
                      controller: reviewC,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        hintText: "Write your review",
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),
                TextButton(
                  onPressed: () async {
                    if (reviewC.text.isEmpty ||
                        rating == 0 ||
                        selectedReviewOption == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Please fill all fields")),
                      );
                      return;
                    }

                    await _submitReview(
                      reviewText: reviewC.text,
                      rating: rating,
                      option: selectedReviewOption!,
                      images: reviewImages,
                    );

                    Navigator.pop(context);
                  },
                  child: const Text("Submit"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _submitReview({
    required String reviewText,
    required int rating,
    required String option,
    required List<String> images,
  }) async {
    final user = FirebaseAuth.instance.currentUser!;

    final orderItem = await _findReviewableOrderItem();

    if (orderItem == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("You can review only after the product is delivered"),
        ),
      );
      return;
    }

    final String orderId = orderItem['orderId'];
    final int itemIndex = orderItem['itemIndex'];

    final alreadyExists = await _alreadyReviewed(orderId, itemIndex);

    if (alreadyExists) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("You have already reviewed this item")),
      );
      return;
    }

    await FirebaseFirestore.instance.collection('reviews').add({
      'userId': user.uid,
      'productId': widget.productId,
      'productTitle': productData?['title'],
      'orderId': orderId,
      'itemIndex': itemIndex,
      'rating': rating,
      'option': option,
      'reviewText': reviewText,
      'images': images,
      'status': 'pending',
      'time': FieldValue.serverTimestamp(),
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Review submitted successfully")),
    );
  }

  Future<void> _checkFavourite() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final snap = await FirebaseFirestore.instance
        .collection('favourites')
        .where('userId', isEqualTo: user.uid)
        .where('productId', isEqualTo: widget.productId)
        .limit(1)
        .get();

    setState(() {
      isFav = snap.docs.isNotEmpty;
    });
  }

  Future<Set<String>> _getReviewedItemKeys() async {
    final user = FirebaseAuth.instance.currentUser!;

    final snap = await FirebaseFirestore.instance
        .collection('reviews')
        .where('userId', isEqualTo: user.uid)
        .where('productId', isEqualTo: widget.productId)
        .get();

    return snap.docs.map((d) => "${d['orderId']}_${d['itemIndex']}").toSet();
  }

  Future<void> _toggleFavourite() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final favRef = FirebaseFirestore.instance.collection('favourites');

    if (isFav) {
      final snap = await favRef
          .where('userId', isEqualTo: user.uid)
          .where('productId', isEqualTo: widget.productId)
          .get();

      for (var d in snap.docs) {
        await d.reference.delete();
      }

      setState(() => isFav = false);
    } else {
      await favRef.add({
        'userId': user.uid,
        'productId': widget.productId,
        'productTitle': productData?['title'] ?? '',
        'time': FieldValue.serverTimestamp(),
      });

      setState(() => isFav = true);
    }
  }

  Future<void> _loadProduct() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('products')
          .doc(widget.productId)
          .get();

      if (!doc.exists) return;

      final data = doc.data()!;
      final Map<String, dynamic> productMap = Map<String, dynamic>.from(data);
      final productTag = productMap['tag']?.toString() ?? '';

      final discount = await _getActiveDiscount(productTag);

      String slidingText = "";
      if (discount != null) {
        final percentage = discount['percentage'] ?? 0;
        final endAt = discount['end_at'] as Timestamp?;
        if (percentage > 0 && endAt != null) {
          slidingText =
              "Enjoy a solid $percentage% discount on this product till ${_formatDate(endAt)}! Hurry up and order now!";
        }
      }

      setState(() {
        productData = productMap;
        imageList = (productMap['images'] is List)
            ? List<String>.from(productMap['images'])
            : [];
        currentImageIndex = 0;

        slidingBannerText = slidingText;
        _animateSlidingText = slidingText.isNotEmpty;
      });

      if (_animateSlidingText) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _controller.reset();
          _controller.forward();
        });
      } else {
        _controller.value = 1.0;
      }
    } catch (e) {
      // keep silent as per original style
    }
  }

  Future<void> _loadReviews() async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('reviews')
          .where('productId', isEqualTo: widget.productId)
          .where('status', isEqualTo: 'approved')
          .orderBy('time', descending: true)
          .get();

      setState(() {
        reviews = snap.docs.map((d) => d.data()).toList();
      });
    } catch (e) {
      debugPrint("Failed to load reviews: $e");
    }
  }

  Future<Map<String, dynamic>?> _findReviewableOrderItem() async {
    final user = FirebaseAuth.instance.currentUser!;

    final ordersSnap = await FirebaseFirestore.instance
        .collection('orders')
        .where('userId', isEqualTo: user.uid)
        .where('status', isEqualTo: 'Delivered')
        .get();

    if (ordersSnap.docs.isEmpty) return null;

    final reviewedKeys = await _getReviewedItemKeys();

    for (final orderDoc in ordersSnap.docs) {
      final items = List<Map<String, dynamic>>.from(orderDoc['items'] ?? []);

      for (int i = 0; i < items.length; i++) {
        if (items[i]['productId'] == widget.productId) {
          final key = "${orderDoc.id}_$i";

          if (!reviewedKeys.contains(key)) {
            return {'orderId': orderDoc.id, 'itemIndex': i, 'item': items[i]};
          }
        }
      }
    }

    return null;
  }

  Future<bool> _alreadyReviewed(String orderId, int itemIndex) async {
    final user = FirebaseAuth.instance.currentUser!;

    final snap = await FirebaseFirestore.instance
        .collection('reviews')
        .where('userId', isEqualTo: user.uid)
        .where('orderId', isEqualTo: orderId)
        .where('itemIndex', isEqualTo: itemIndex)
        .limit(1)
        .get();

    return snap.docs.isNotEmpty;
  }

  Future<Map<String, dynamic>?> _getActiveDiscount(String productTag) async {
    try {
      final now = Timestamp.now();

      final snap = await FirebaseFirestore.instance
          .collection('discounts')
          .where('start_at', isLessThanOrEqualTo: now)
          .where('end_at', isGreaterThan: now)
          .get();

      Map<String, dynamic>? allDiscount;

      for (final doc in snap.docs) {
        final data = doc.data();
        final tags = List<String>.from(data['tags'] ?? []);

        if (tags.contains(productTag)) return data;
        if (tags.contains("All")) allDiscount ??= data;
      }

      return allDiscount;
    } catch (e) {
      return null;
    }
  }

  Future<void> _loadUser() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      setState(() {
        username = "";
        userRole = "user";
        isLoggedIn = false;
      });
      return;
    }
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser.uid)
        .get();

    final data = doc.data() ?? {};
    setState(() {
      username = (data['name'] ?? "").toString();
      userRole = (data['role'] ?? "user").toString();
      isLoggedIn = true;
    });
  }

  Future<void> _logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final product = productData ?? <String, dynamic>{};

    final int totalSold = (product['total_sold'] as num?)?.toInt() ?? 0;
    final productTitle = (product['title'] ?? '').toString();
    final productPrice = (product['price'] ?? '').toString();
    final productQuantity = product['quantity'] != null
        ? int.tryParse(product['quantity'].toString()) ?? 0
        : 0;
    final productDescription = (product['description'] ?? '').toString();
    final categories = (product['categories'] is List)
        ? List<String>.from(product['categories'])
        : [];
    final images = (product['images'] is List)
        ? List<String>.from(product['images'])
        : [];

    return Scaffold(
      backgroundColor: const Color(0xFFFDF1F5),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                TopBar(
                  onMenuTap: () {
                    setState(() {
                      menuVisible = !menuVisible;
                    });
                  },
                ),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 15),
                          child: SlideTransition(
                            position: _slideAnimation,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(18),
                              child: Stack(
                                children: [
                                  if (images.isNotEmpty)
                                    Image.memory(
                                      base64Decode(images[currentImageIndex]),
                                      height: 350,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                    )
                                  else
                                    Container(
                                      height: 260,
                                      width: double.infinity,
                                      color: Colors.grey.shade300,
                                      child: const Center(
                                        child: Icon(Icons.image, size: 40),
                                      ),
                                    ),

                                  if (images.isNotEmpty &&
                                      currentImageIndex > 0)
                                    Positioned(
                                      left: 10,
                                      top: 0,
                                      bottom: 0,
                                      child: GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            currentImageIndex =
                                                (currentImageIndex - 1).clamp(
                                                  0,
                                                  images.length - 1,
                                                );
                                          });
                                        },
                                        child: Container(
                                          width: 38,
                                          height: 38,
                                          decoration: BoxDecoration(
                                            color: Colors.black.withOpacity(
                                              0.3,
                                            ),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.arrow_back_ios,
                                            color: Colors.white,
                                            size: 20,
                                          ),
                                        ),
                                      ),
                                    ),

                                  if (images.isNotEmpty &&
                                      currentImageIndex < images.length - 1)
                                    Positioned(
                                      right: 10,
                                      top: 0,
                                      bottom: 0,
                                      child: GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            currentImageIndex =
                                                (currentImageIndex + 1).clamp(
                                                  0,
                                                  images.length - 1,
                                                );
                                          });
                                        },
                                        child: Container(
                                          width: 38,
                                          height: 38,
                                          decoration: BoxDecoration(
                                            color: Colors.black.withOpacity(
                                              0.3,
                                            ),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.arrow_forward_ios,
                                            color: Colors.white,
                                            size: 20,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 4),

                        AnimatedOpacity(
                          opacity: slidingBannerText.isEmpty ? 0 : 1,
                          duration: const Duration(milliseconds: 400),
                          child: SlidingText(
                            text: slidingBannerText.isEmpty
                                ? " "
                                : slidingBannerText,
                            speed: 30,
                          ),
                        ),

                        SizedBox(height: slidingBannerText.isNotEmpty ? 12 : 0),

                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 15,
                            vertical: 12,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  productTitle,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 22,
                                  ),
                                ),
                              ),
                              FutureBuilder<Map<String, dynamic>?>(
                                future: _getActiveDiscount(
                                  product['tag']?.toString() ?? '',
                                ),
                                builder: (context, snapshot) {
                                  final originalPrice =
                                      int.tryParse(productPrice) ?? 0;

                                  if (!snapshot.hasData ||
                                      snapshot.data == null) {
                                    return Text(
                                      "৳$originalPrice",
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 20,
                                      ),
                                    );
                                  }

                                  final discount = snapshot.data!;
                                  final percentage =
                                      discount['percentage'] ?? 0;

                                  if (percentage == 0) {
                                    return Text(
                                      "৳$originalPrice",
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 20,
                                      ),
                                    );
                                  }

                                  final discountedPrice =
                                      (originalPrice -
                                              (originalPrice *
                                                  percentage /
                                                  100))
                                          .round();

                                  return Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        "৳$originalPrice",
                                        style: const TextStyle(
                                          decoration:
                                              TextDecoration.lineThrough,
                                          fontSize: 14,
                                          color: Colors.black54,
                                        ),
                                      ),
                                      Text(
                                        "৳$discountedPrice",
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 20,
                                          color: Color(0xFFB564F7),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 15),
                          child: Row(
                            children: [
                              const Text(
                                "Options",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 17,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                "$productQuantity in stock | Sold: $totalSold",
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.black54,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),

                              const SizedBox(width: 12),
                              GestureDetector(
                                onTap: _toggleFavourite,
                                child: Icon(
                                  isFav
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                  color: const Color(0xFFB564F7),
                                  size: 26,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),
                        SizedBox(
                          height: 50,
                          child: ListView(
                            padding: const EdgeInsets.fromLTRB(15, 10, 0, 0),
                            scrollDirection: Axis.horizontal,
                            children: categories.map((cat) {
                              return _OptionChip(
                                label: cat,
                                selected: selectedOption == cat,
                                onTap: () {
                                  setState(() => selectedOption = cat);
                                },
                              );
                            }).toList(),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(15, 12, 15, 5),
                          child: Row(
                            children: [
                              const Text(
                                "Quantity:",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 17,
                                ),
                              ),
                              const SizedBox(width: 15),
                              Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1D9FB),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                child: Row(
                                  children: [
                                    GestureDetector(
                                      onTap: () {
                                        if (quantity > 1) {
                                          setState(() => quantity--);
                                        }
                                      },
                                      child: const Icon(Icons.remove, size: 22),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      quantity.toString(),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    GestureDetector(
                                      onTap: () {
                                        if (quantity >= 10) {
                                          showDialog(
                                            context: context,
                                            builder: (_) => AlertDialog(
                                              title: const Text(
                                                "Limit reached",
                                              ),
                                              content: const Text(
                                                "Maximum Quantity for one order is 10",
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () =>
                                                      Navigator.pop(context),
                                                  child: const Text("OK"),
                                                ),
                                              ],
                                            ),
                                          );
                                          return;
                                        }
                                        if (quantity < productQuantity) {
                                          setState(() => quantity++);
                                        }
                                      },
                                      child: const Icon(Icons.add, size: 22),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        if (productDescription.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(15, 10, 15, 3),
                            child: const Text(
                              "Description",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 17,
                              ),
                            ),
                          ),
                        if (productDescription.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 15),
                            child: Text(
                              productDescription,
                              style: const TextStyle(fontSize: 14, height: 1.4),
                            ),
                          ),
                        const SizedBox(height: 20),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 15,
                            vertical: 15,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: () async {
                                    final user =
                                        FirebaseAuth.instance.currentUser;

                                    if (user == null) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text("Please log in first"),
                                        ),
                                      );
                                      return;
                                    }

                                    if (selectedOption == null) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            "Please select an option",
                                          ),
                                        ),
                                      );
                                      return;
                                    }

                                    try {
                                      final unitPrice =
                                          int.tryParse(
                                            productData?['price'].toString() ??
                                                '0',
                                          ) ??
                                          0;

                                      final discount = await _getActiveDiscount(
                                        productData?['tag']?.toString() ?? '',
                                      );

                                      int discountPercentage = 0;
                                      int discountedUnitPrice = 0;
                                      int discountedTotalPrice = 0;
                                      Timestamp? discountEndAt;

                                      if (discount != null) {
                                        discountPercentage =
                                            discount['percentage'] ?? 0;
                                        discountEndAt = discount['end_at'];

                                        if (discountPercentage > 0) {
                                          discountedUnitPrice =
                                              (unitPrice -
                                                      (unitPrice *
                                                          discountPercentage /
                                                          100))
                                                  .round();
                                          discountedTotalPrice =
                                              discountedUnitPrice * quantity;
                                        }
                                      }

                                      final totalPrice = unitPrice * quantity;

                                      await FirebaseFirestore.instance
                                          .collection('cart')
                                          .add({
                                            'userId': user.uid,
                                            'productId': widget.productId,
                                            'title': productData?['title'],
                                            'unitPrice': unitPrice,
                                            'quantity': quantity,
                                            'totalPrice': totalPrice,
                                            'discountPercentage':
                                                discountPercentage,
                                            'discountedUnitPrice':
                                                discountedUnitPrice,
                                            'discountedTotalPrice':
                                                discountedTotalPrice,
                                            'discountEndAt': discountEndAt,
                                            'option': selectedOption,
                                            'time':
                                                FieldValue.serverTimestamp(),
                                          });

                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text("Added to cart"),
                                        ),
                                      );
                                    } catch (e) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            "Failed to add to cart",
                                          ),
                                        ),
                                      );
                                    }
                                  },

                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFB564F7),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Center(
                                      child: Text(
                                        "Add to Cart",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 15),
                              Expanded(
                                child: GestureDetector(
                                  onTap: _showAddReviewDialog,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFB564F7),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Center(
                                      child: Text(
                                        "Add Review",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 15),

                        Center(
                          child: SizedBox(
                            height: 300,
                            width: 350,
                            child: reviews.isEmpty
                                ? const Center(
                                    child: Text(
                                      "No reviews yet",
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.black54,
                                      ),
                                    ),
                                  )
                                : Stack(
                                    children: [
                                      PageView.builder(
                                        controller: reviewPageController,
                                        itemCount: reviews.length,
                                        onPageChanged: (index) {
                                          setState(
                                            () => currentReviewIndex = index,
                                          );
                                        },
                                        itemBuilder: (context, index) {
                                          final r = reviews[index];
                                          final reviewTime =
                                              (r['time'] as Timestamp?)
                                                  ?.toDate();
                                          return Padding(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 0,
                                            ),
                                            child: Card(
                                              color: const Color(0xFFF1D9FB),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: Padding(
                                                padding: const EdgeInsets.all(
                                                  12,
                                                ),
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    FutureBuilder<
                                                      DocumentSnapshot<
                                                        Map<String, dynamic>
                                                      >
                                                    >(
                                                      future: FirebaseFirestore
                                                          .instance
                                                          .collection('users')
                                                          .doc(r['userId'])
                                                          .get(),
                                                      builder: (context, snapshot) {
                                                        final userName =
                                                            snapshot.hasData &&
                                                                snapshot.data !=
                                                                    null
                                                            ? (snapshot.data!
                                                                          .data()?['name']
                                                                      as String?) ??
                                                                  'User'
                                                            : 'User';
                                                        return Text(
                                                          userName,
                                                          style:
                                                              const TextStyle(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                fontSize: 16,
                                                              ),
                                                        );
                                                      },
                                                    ),

                                                    const SizedBox(height: 4),

                                                    if (reviewTime != null)
                                                      Text(
                                                        "${reviewTime.day}-${reviewTime.month}-${reviewTime.year} ${reviewTime.hour}:${reviewTime.minute.toString().padLeft(2, '0')}",
                                                        style: const TextStyle(
                                                          fontSize: 12,
                                                          color: Colors.black54,
                                                        ),
                                                      ),

                                                    const SizedBox(height: 6),

                                                    if (r['option'] != null)
                                                      Text(
                                                        "Option: ${r['option']}",
                                                        style: const TextStyle(
                                                          fontSize: 14,
                                                          fontWeight:
                                                              FontWeight.w500,
                                                        ),
                                                      ),

                                                    const SizedBox(height: 6),

                                                    if (r['images'] != null &&
                                                        (r['images'] as List)
                                                            .isNotEmpty)
                                                      SizedBox(
                                                        height: 60,
                                                        child: ListView(
                                                          scrollDirection:
                                                              Axis.horizontal,
                                                          children: (r['images'] as List)
                                                              .map<Widget>(
                                                                (
                                                                  img,
                                                                ) => Padding(
                                                                  padding:
                                                                      const EdgeInsets.only(
                                                                        right:
                                                                            6,
                                                                      ),
                                                                  child: ClipRRect(
                                                                    borderRadius:
                                                                        BorderRadius.circular(
                                                                          8,
                                                                        ),
                                                                    child: Image.memory(
                                                                      base64Decode(
                                                                        img,
                                                                      ),
                                                                      width: 60,
                                                                      height:
                                                                          60,
                                                                      fit: BoxFit
                                                                          .cover,
                                                                    ),
                                                                  ),
                                                                ),
                                                              )
                                                              .toList(),
                                                        ),
                                                      ),

                                                    const SizedBox(height: 6),

                                                    Text(
                                                      r['reviewText'] ?? '',
                                                      maxLines: 3,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),

                                                    const SizedBox(height: 6),
                                                    Row(
                                                      children: List.generate(5, (
                                                        i,
                                                      ) {
                                                        return Icon(
                                                          i < (r['rating'] ?? 0)
                                                              ? Icons.star
                                                              : Icons
                                                                    .star_border,
                                                          color: Colors.amber,
                                                          size: 18,
                                                        );
                                                      }),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                      ),

                                      if (currentReviewIndex > 0)
                                        Positioned(
                                          left: 8,
                                          top: 0,
                                          bottom: 0,
                                          child: Center(
                                            child: GestureDetector(
                                              onTap: () {
                                                reviewPageController
                                                    .previousPage(
                                                      duration: const Duration(
                                                        milliseconds: 300,
                                                      ),
                                                      curve: Curves.easeInOut,
                                                    );
                                              },
                                              child: CircleAvatar(
                                                radius: 18,
                                                backgroundColor: Colors.black
                                                    .withOpacity(0.2),
                                                child: const Icon(
                                                  Icons.arrow_back_ios,
                                                  color: Colors.white,
                                                  size: 16,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),

                                      if (currentReviewIndex <
                                          reviews.length - 1)
                                        Positioned(
                                          right: 8,
                                          top: 0,
                                          bottom: 0,
                                          child: Center(
                                            child: GestureDetector(
                                              onTap: () {
                                                reviewPageController.nextPage(
                                                  duration: const Duration(
                                                    milliseconds: 300,
                                                  ),
                                                  curve: Curves.easeInOut,
                                                );
                                              },
                                              child: CircleAvatar(
                                                radius: 18,
                                                backgroundColor: Colors.black
                                                    .withOpacity(0.2),
                                                child: const Icon(
                                                  Icons.arrow_forward_ios,
                                                  color: Colors.white,
                                                  size: 16,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                          ),
                        ),

                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ),
              ],
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
                    } else if (value == "Terms and Conditions") {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const TermsManage()),
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
          if (index == 0) {
            Navigator.pushNamedAndRemoveUntil(context, '/home', (_) => false);
          } else if (index == 1) {
            Navigator.pushNamedAndRemoveUntil(context, '/offer', (_) => false);
          } else if (index == 2) {
            Navigator.pushNamedAndRemoveUntil(context, '/cart', (_) => false);
          } else if (index == 3) {
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/profile',
              (_) => false,
            );
          }
        },
      ),
    );
  }
}
