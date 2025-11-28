import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shop_cutesy/screens/auth/sign_up.dart';
import 'package:shop_cutesy/screens/cart_page.dart';
import 'package:shop_cutesy/screens/product_page.dart';
import 'package:shop_cutesy/screens/profile_page.dart';
import 'package:shop_cutesy/screens/services/authentication.dart';
import 'package:shop_cutesy/utils/purple_box.dart';
import 'package:shop_cutesy/widgets/bottom_navigation.dart';
import 'package:shop_cutesy/widgets/sliding_text.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
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
  bool _animate = false;

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
    if (FirebaseAuth.instance.currentUser == null) {
      username = "";
      setState(() => _animate = false);
      return;
    }

    username = await AuthService().getUsername() ?? "";
    await Future.delayed(const Duration(milliseconds: 400));
    setState(() => _animate = true);
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
              child: Row(
                children: [
                  const Icon(Icons.menu, size: 30),
                  const SizedBox(width: 10),
                  Image.asset("assets/images/cutesy.png", width: 70),
                  const Spacer(),

                  if (FirebaseAuth.instance.currentUser != null)
                    GestureDetector(
                      onTap: () async {
                        await FirebaseAuth.instance.signOut();

                        final prefs = await SharedPreferences.getInstance();
                        await prefs.remove("savedEmail");
                        await prefs.remove("savedPass");

                        setState(() {});
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFB564F7),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          "Log Out",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),

                  if (FirebaseAuth.instance.currentUser == null)
                    GestureDetector(
                      onTap: () => Navigator.pushNamed(context, "/login"),
                      child: const Text(
                        "Log In",
                        style: TextStyle(
                          color: btnPurple,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                ],
              ),
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
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 40),
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
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
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
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: bottomIndex,
        onTap: (index) {
          setState(() {
            bottomIndex = index;
          });

          if (index == 2) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CartPage()),
            );
          }

          if (index == 3) {
            if (AuthService().isLoggedIn) {
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
