import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shop_cutesy/main.dart';
import 'package:shop_cutesy/screens/auth/sign_up.dart';
import 'package:shop_cutesy/screens/cart_page.dart';
import 'package:shop_cutesy/screens/management.dart';
import 'package:shop_cutesy/screens/offer_page.dart';
import 'package:shop_cutesy/screens/product_page.dart';
import 'package:shop_cutesy/screens/profile_page.dart';
import 'package:shop_cutesy/screens/services/authentication.dart';
import 'package:shop_cutesy/widgets/bottom_navigation.dart';
import 'package:shop_cutesy/widgets/menu_drop.dart';
import 'package:shop_cutesy/widgets/sliding_text.dart';
import 'package:shop_cutesy/widgets/top_bar.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with RouteAware {
  int bottomIndex = 0;
  final List<String> filters = const [
    'All',
    'Wallets',
    'Keychains',
    'Plushy',
    'Bow',
    'Charms',
    'Bookmarks',
    'Nails',
    'Stationary',
    'Wax seal',
  ];

  late String filterSelected;

  final List<Map<String, dynamic>> sampleProducts = [
    {
      "name": "Ice Cream Wallet",
      "price": "950/-",
      "image": "assets/images/wallet1.webp",
      "stock": 12,
      "isFav": false,
    },
    {
      "name": "Washi – PET TAPE",
      "price": "1250/-",
      "image": "assets/images/stationary1.jpg",
      "stock": 12,
      "isFav": false,
    },
    {
      "name": "KNY Plushy Big",
      "price": "1350/-",
      "image": "assets/images/plush1.jpeg",
      "stock": 12,
      "isFav": false,
    },
    {
      "name": "Jelly Fish Charm",
      "price": "750/-",
      "image": "assets/images/charm5.jpg",
      "stock": 12,
      "isFav": false,
    },
  ];

  String username = "";
  String userRole = "user";
  bool _animate = false;
  bool menuVisible = false;

  @override
  void initState() {
    super.initState();

    FirebaseAuth.instance.authStateChanges().listen((user) {
      loadUser();
      setState(() {});
    });

    filterSelected = filters[0];
    loadUser();
  }

  void loadUser() async {
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
      backgroundColor: const Color(0xFFFDF1F5),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
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
                            AnimatedSlide(
                              offset: _animate
                                  ? const Offset(0, 0)
                                  : const Offset(-1.5, 0),
                              duration: const Duration(milliseconds: 600),
                              curve: Curves.easeOut,
                              child: SlidingText(
                                text:
                                    "Welcome to Cutesy $username! Enjoy our biggest sales this year and stay connected with us.",
                                speed: 40,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  const SizedBox.shrink(),

                const Row(
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
                        decoration: InputDecoration(
                          hintText: 'search',
                          prefixIcon: Icon(Icons.search),
                          border: border,
                          enabledBorder: border,
                          focusedBorder: border,
                        ),
                      ),
                    ),
                  ],
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

                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.all(15),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 20,
                          crossAxisSpacing: 15,
                          childAspectRatio: 0.72,
                        ),
                    itemCount: sampleProducts.length,
                    itemBuilder: (context, index) {
                      final product = sampleProducts[index];

                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ProductPage(product: product),
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
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ClipRRect(
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(18),
                                ),
                                child: Image.asset(
                                  product["image"],
                                  height: 150,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                              ),

                              Padding(
                                padding: const EdgeInsets.all(8),
                                child: Text(
                                  product["name"],
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              ),

                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8.0,
                                ),
                                child: Row(
                                  children: [
                                    Text(
                                      "Tk. ${product["price"]}",
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const Spacer(),
                                    const Icon(
                                      Icons.favorite_border,
                                      color: Color(0xFFB564F7),
                                    ),
                                  ],
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
              MaterialPageRoute(builder: (_) => const OfferPage()),
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
