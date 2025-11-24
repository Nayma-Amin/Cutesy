import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final List<String> filters = const[
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
  
  @override
  void initState() {
    super.initState();
    filterSelected = filters[0];
  }
   

  @override
  Widget build(BuildContext context) {
    const border = OutlineInputBorder(
      borderSide: BorderSide(
        color: Color(0xFFC9C7C7)),
      borderRadius: BorderRadius.horizontal(
        left: Radius.circular(40)),
    );

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
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
              height: 100,
              child: ListView.builder(
                    itemCount: filters.length,
                    scrollDirection: Axis.horizontal,
                    itemBuilder: (context, index) {
                      final filter = filters[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8.0),
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              filterSelected = filter;
                            });
                          },
                          child: Chip(
                            backgroundColor: filterSelected == filter ? Theme.of(context).colorScheme.primary :const Color(0xFFF1D9FB),
                            label: Text(filter, 
                            style: TextStyle(
                              color: Color(0xFF000000),
                            ),
                            ),
                            padding: EdgeInsets.symmetric(
                              horizontal: 15,
                              vertical: 8,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      );
                    },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
