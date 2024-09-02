import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:convert';
import 'package:flutter/services.dart';


//Source Code:

//https://stackoverflow.com/questions/71294190/how-to-read-local-json-file-in-flutter
//https://stackoverflow.com/questions/58908968/how-to-implement-a-flutter-search-app-bar
//ChatGPT "How to make a table from json file" and "How to implement riverpod state management"


// FutureProvider to load restaurants from a JSON file
final restaurantProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  try {
    // Load the JSON file
    final String response = await rootBundle.loadString('assets/restaurants.json');
    
    // Decode the JSON data and ensure correct typing
    final List<Map<String, dynamic>> data = (json.decode(response) as List)
        .map((item) => item as Map<String, dynamic>)
        .toList();
    
    // Return the parsed list
    return data;
  } catch (error) {
    // Handle the error (file not found, parse error, etc.)
    throw Exception('Failed to load restaurants data: $error');
  }
});

// State provider for the search query
final searchQueryProvider = StateProvider<String>((ref) {
  return '';
});

// Computed provider for the filtered list of restaurants
final filteredRestaurantProvider = Provider<List<Map<String, dynamic>>>((ref) {
  final searchQuery = ref.watch(searchQueryProvider).toLowerCase();
  final allRestaurants = ref.watch(restaurantProvider).maybeWhen(
        data: (restaurants) => restaurants,
        orElse: () => [],
      );

  // Ensure we only filter if allRestaurants is correctly typed
return allRestaurants.where((restaurant) {
    final restaurantName = restaurant['name'].toLowerCase();
    return restaurantName.contains(searchQuery);
  }).toList()
  .cast<Map<String, dynamic>>(); 
});

void main() {
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: HomePage(),
    );
  }
}

class HomePage extends ConsumerWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filteredRestaurants = ref.watch(filteredRestaurantProvider);
    final asyncRestaurants = ref.watch(restaurantProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Restaurants'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Search field
            TextField(
              decoration: const InputDecoration(
                labelText: 'Search by name',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                ref.read(searchQueryProvider.notifier).state = value;
              },
            ),
            const SizedBox(height: 16),
            // Handling the state of asyncRestaurants
            asyncRestaurants.when(
              data: (_) => filteredRestaurants.isNotEmpty
                  ? Expanded(
                      child: ListView.builder(
                        itemCount: filteredRestaurants.length,
                        itemBuilder: (context, index) {
                          return Card(
                            margin: const EdgeInsets.all(10),
                            child: ListTile(
                              leading: Text(filteredRestaurants[index]['id'].toString()),
                              title: Text(filteredRestaurants[index]['name']),
                              subtitle: Text(filteredRestaurants[index]['cuisine']),
                            ),
                          );
                        },
                      ),
                    )
                  : const Text('No restaurants found'),
              loading: () => const CircularProgressIndicator(),
              error: (error, stack) => Text('Error: $error'),
            ),
          ],
        ),
      ),
    );
  }
}
