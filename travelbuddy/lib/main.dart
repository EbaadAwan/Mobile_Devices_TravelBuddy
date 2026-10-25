import 'package:flutter/material.dart';
import 'services/nearby_attractions_service.dart';

void main() {
  runApp(const TravelBuddyApp());
}

const Color travelCyan = Color(0xFF08C6DF);
const Color travelBackground = Color(0xFFF5F6F7);
const Color travelText = Color(0xFF292929);

class TravelBuddyApp extends StatelessWidget {
  const TravelBuddyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TravelBuddy',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: travelBackground,
        colorScheme: ColorScheme.fromSeed(
          seedColor: travelCyan,
          primary: travelCyan,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: travelCyan,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
      home: const TravelBuddyShell(),
    );
  }
}

class Destination {
  const Destination({
    required this.name,
    required this.location,
    required this.rating,
    required this.distance,
    required this.description,
    required this.imageUrl,
    this.activity = 'Quiet',
    this.hours = '9:00 AM - 10:00 PM',
  });

  final String name;
  final String location;
  final double rating;
  final String distance;
  final String description;
  final String imageUrl;
  final String activity;
  final String hours;
}

const List<Destination> sampleDestinations = [
  Destination(
    name: 'Oshawa Museum',
    location: 'Lakeview Park, Oshawa',
    rating: 4.3,
    distance: '1.8 km',
    description:
    'A historic site in Lakeview Park that tells the story of Oshawa through its local heritage.',
    imageUrl:
    'https://dynamic-media-cdn.tripadvisor.com/media/photo-o/1b/7f/af/78/lakeview-park.jpg?w=1100&h=600&s=1',
  ),
  Destination(
    name: 'Lakeview Park',
    location: 'Oshawa, Ontario',
    rating: 4.8,
    distance: '2.4 km',
    description:
    'A relaxing waterfront park with walking paths, green spaces, and views of Lake Ontario.',
    imageUrl:
    'https://dynamic-media-cdn.tripadvisor.com/media/photo-o/1b/7f/af/78/lakeview-park.jpg?w=1100&h=600&s=1',
  ),
  Destination(
    name: 'Parkwood Estate',
    location: ' downtown Oshawa',
    rating: 4.6,
    distance: '3.1 km',
    description:
    'Explore a historic estate with gardens, architecture, and seasonal tours.',
    imageUrl:
    'https://dynamic-media-cdn.tripadvisor.com/media/photo-o/1b/7f/af/78/lakeview-park.jpg?w=1100&h=600&s=1',
  ),
];

class PlannedStop {
  PlannedStop({required this.destination, required this.dateTime});

  final Destination destination;
  DateTime dateTime;
}

class TravelBuddyShell extends StatefulWidget {
  const TravelBuddyShell({super.key});

  @override
  State<TravelBuddyShell> createState() => _TravelBuddyShellState();
}

class _TravelBuddyShellState extends State<TravelBuddyShell> {
  int _selectedTab = 0;
  final Set<String> _favoriteNames = {'Lakeview Park'};
  final List<PlannedStop> _plannedStops = [
    PlannedStop(
      destination: sampleDestinations[1],
      dateTime: DateTime.now().add(const Duration(days: 3)),
    ),
    PlannedStop(
      destination: sampleDestinations[0],
      dateTime: DateTime.now().add(const Duration(days: 4)),
    ),
  ];

  String _tripName = 'Toronto Trip';
  double _budget = 500;

  List<Destination> get _favorites => sampleDestinations
      .where((destination) => _favoriteNames.contains(destination.name))
      .toList();

  void _toggleFavorite(Destination destination) {
    setState(() {
      if (!_favoriteNames.add(destination.name)) {
        _favoriteNames.remove(destination.name);
      }
    });
  }

  void _addStop(Destination destination) {
    if (_plannedStops.any((stop) => stop.destination.name == destination.name)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${destination.name} is already in your trip.')),
      );
      return;
    }
    setState(() {
      _plannedStops.add(
        PlannedStop(
          destination: destination,
          dateTime: DateTime.now().add(const Duration(days: 3)),
        ),
      );
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${destination.name} added to your trip.')),
    );
  }

  void _removeStop(PlannedStop stop) {
    setState(() => _plannedStops.remove(stop));
  }

  void _showTripDialog() {
    final controller = TextEditingController(text: _tripName);
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Edit trip'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Trip name',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              setState(() {
                _tripName = controller.text.trim().isEmpty
                    ? 'My Trip'
                    : controller.text.trim();
              });
              Navigator.pop(dialogContext);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showBudgetDialog() {
    final controller = TextEditingController(text: _budget.toStringAsFixed(0));
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Set trip budget'),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            prefixText: '\$ ',
            labelText: 'Budget',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final value = double.tryParse(controller.text);
              if (value != null && value >= 0) {
                setState(() => _budget = value);
              }
              Navigator.pop(dialogContext);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomePage(
        favorites: _favoriteNames,
        onToggleFavorite: _toggleFavorite,
        onAddToTrip: _addStop,
        onOpenFavorites: () => setState(() => _selectedTab = 1),
        onOpenPlanner: () => setState(() => _selectedTab = 2),
      ),
      FavoritesPage(
        favorites: _favorites,
        onToggleFavorite: _toggleFavorite,
        onAddToTrip: _addStop,
      ),
      TripPlannerPage(
        tripName: _tripName,
        budget: _budget,
        stops: _plannedStops,
        onEditTrip: _showTripDialog,
        onEditBudget: _showBudgetDialog,
        onAddDestination: () => _showDestinationPicker(),
        onRemoveStop: _removeStop,
      ),
    ];

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _TravelBuddyHeader(
              title: ['TravelBuddy', 'Favourites', 'Trip Planner'][_selectedTab],
              onMenuTap: _showMenu,
            ),
            Expanded(child: pages[_selectedTab]),
          ],
        ),
      ),
      bottomNavigationBar: _BottomNavigation(
        selectedIndex: _selectedTab,
        onTap: (index) => setState(() => _selectedTab = index),
      ),
    );
  }

  void _showDestinationPicker() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: Text(
                'Add a destination',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            ...sampleDestinations.map(
                  (destination) => ListTile(
                leading: const Icon(Icons.place_outlined, color: travelCyan),
                title: Text(destination.name),
                subtitle: Text(destination.location),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _addStop(destination);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMenu() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.home_outlined),
              title: const Text('Home'),
              onTap: () {
                Navigator.pop(sheetContext);
                setState(() => _selectedTab = 0);
              },
            ),
            ListTile(
              leading: const Icon(Icons.favorite_border),
              title: const Text('Favourites'),
              onTap: () {
                Navigator.pop(sheetContext);
                setState(() => _selectedTab = 1);
              },
            ),
            ListTile(
              leading: const Icon(Icons.calendar_month_outlined),
              title: const Text('Trip Planner'),
              onTap: () {
                Navigator.pop(sheetContext);
                setState(() => _selectedTab = 2);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _TravelBuddyHeader extends StatelessWidget {
  const _TravelBuddyHeader({
    required this.title,
    required this.onMenuTap,
  });

  final String title;
  final VoidCallback onMenuTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      color: travelCyan,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          const Icon(Icons.explore_outlined, color: Colors.white, size: 25),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          IconButton(
            onPressed: onMenuTap,
            tooltip: 'Open menu',
            icon: const Icon(Icons.menu, color: Colors.white, size: 32),
          ),
        ],
      ),
    );
  }
}

class _BottomNavigation extends StatelessWidget {
  const _BottomNavigation({
    required this.selectedIndex,
    required this.onTap,
  });

  final int selectedIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    const items = [
      (Icons.home_rounded, 'Home'),
      (Icons.favorite_rounded, 'Favourites'),
      (Icons.calendar_month_rounded, 'Trip Planner'),
    ];

    return BottomNavigationBar(
      currentIndex: selectedIndex,
      onTap: onTap,
      type: BottomNavigationBarType.fixed,
      backgroundColor: travelCyan,
      selectedItemColor: Colors.white,
      unselectedItemColor: Colors.white70,
      selectedLabelStyle:
      const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
      unselectedLabelStyle: const TextStyle(fontSize: 11),
      items: items
          .map(
            (item) => BottomNavigationBarItem(
          icon: Icon(item.$1),
          label: item.$2,
        ),
      )
          .toList(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
    required this.favorites,
    required this.onToggleFavorite,
    required this.onAddToTrip,
    required this.onOpenFavorites,
    required this.onOpenPlanner,
  });

  final Set<String> favorites;
  final ValueChanged<Destination> onToggleFavorite;
  final ValueChanged<Destination> onAddToTrip;
  final VoidCallback onOpenFavorites;
  final VoidCallback onOpenPlanner;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _isLoadingNearby = false;
  String? _nearbyError;
  List<NearbyAttraction> _nearbyResults = [];
  bool _hasSearched = false;

  Future<void> _findNearbyAttractions() async {
    setState(() {
      _isLoadingNearby = true;
      _nearbyError = null;
      _hasSearched = true;
    });

    // 1. Check location permission
    final hasPermission = await NearbyAttractionsService.checkLocationPermission();
    if (!hasPermission) {
      setState(() {
        _isLoadingNearby = false;
        _nearbyError = 'Location permission denied. Please enable GPS and allow location access.';
      });
      return;
    }

    // 2. Get current position
    final position = await NearbyAttractionsService.getCurrentPosition();
    if (position == null) {
      setState(() {
        _isLoadingNearby = false;
        _nearbyError = 'Unable to get your current location. Make sure GPS is enabled.';
      });
      return;
    }

    // 3. Fetch nearby attractions from API
    try {
      final results = await NearbyAttractionsService.fetchNearbyAttractions(
        latitude: position.latitude,
        longitude: position.longitude,
        radius: 5000,
      );
      setState(() {
        _nearbyResults = results;
        _isLoadingNearby = false;
      });
    } catch (e) {
      setState(() {
        _nearbyError = 'Failed to load nearby attractions: $e';
        _isLoadingNearby = false;
      });
    }
  }

  Destination _toDestination(NearbyAttraction attraction) {
    return Destination(
      name: attraction.name,
      location: attraction.address.isNotEmpty ? attraction.address : attraction.category,
      rating: attraction.rating > 0 ? attraction.rating : 4.0,
      distance: '${attraction.distanceKm.toStringAsFixed(1)} km',
      description: '${attraction.category} near you.',
      imageUrl: attraction.imageUrl.isNotEmpty
          ? attraction.imageUrl
          : 'https://dynamic-media-cdn.tripadvisor.com/media/photo-o/1b/7f/af/78/lakeview-park.jpg?w=1100&h=600&s=1',
      activity: 'Quiet',
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 20),
      children: [
        const Text(
          'Discover places near you',
          style: TextStyle(
            color: travelText,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 5),
        const Text(
          'Find popular attractions around Oshawa.',
          style: TextStyle(color: Colors.black54, fontSize: 14),
        ),
        const SizedBox(height: 16),
        TextField(
          decoration: InputDecoration(
            hintText: 'Search attractions',
            prefixIcon: const Icon(Icons.search),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide.none,
            ),
          ),
          onSubmitted: (query) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  query.trim().isEmpty
                      ? 'Enter a place to search.'
                      : 'Needs search function',
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 14),

        // ✅ NEW: Find Nearby Attractions Button
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: _isLoadingNearby ? null : _findNearbyAttractions,
            icon: _isLoadingNearby
                ? const SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.my_location_rounded),
            label: Text(_isLoadingNearby ? 'Finding...' : 'Find Nearby Attractions'),
            style: FilledButton.styleFrom(
              backgroundColor: travelCyan,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),

        // Show error if any
        if (_nearbyError != null) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _nearbyError!,
                    style: TextStyle(color: Colors.red.shade700, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
        ],

        // Show nearby results when available
        if (_hasSearched && _nearbyResults.isNotEmpty) ...[
          Row(
            children: [
              Expanded(
                child: Text(
                  'Nearby attractions (${_nearbyResults.length})',
                  style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
                ),
              ),
              TextButton.icon(
                onPressed: widget.onOpenFavorites,
                icon: const Icon(Icons.favorite_border, size: 18),
                label: const Text('Favourites'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ..._nearbyResults.map(
            (attraction) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: DestinationCard(
                destination: _toDestination(attraction),
                isFavorite: widget.favorites.contains(attraction.name),
                onToggleFavorite: () => widget.onToggleFavorite(_toDestination(attraction)),
                onAddToTrip: () => widget.onAddToTrip(_toDestination(attraction)),
                onTap: () => _showDetails(context, _toDestination(attraction)),
              ),
            ),
          ),
        ] else if (!_hasSearched) ...[
          // Original section shown before user taps button
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Nearby attractions',
                  style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
                ),
              ),
              TextButton.icon(
                onPressed: widget.onOpenFavorites,
                icon: const Icon(Icons.favorite_border, size: 18),
                label: const Text('Favourites'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...sampleDestinations.map(
            (destination) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: DestinationCard(
                destination: destination,
                isFavorite: widget.favorites.contains(destination.name),
                onToggleFavorite: () => widget.onToggleFavorite(destination),
                onAddToTrip: () => widget.onAddToTrip(destination),
                onTap: () => _showDetails(context, destination),
              ),
            ),
          ),
        ],

        const SizedBox(height: 4),
        OutlinedButton.icon(
          onPressed: widget.onOpenPlanner,
          icon: const Icon(Icons.calendar_month_outlined),
          label: const Text('Plan a trip'),
          style: OutlinedButton.styleFrom(
            foregroundColor: travelCyan,
            side: const BorderSide(color: travelCyan),
            padding: const EdgeInsets.symmetric(vertical: 13),
          ),
        ),
      ],
    );
  }
}

class FavoritesPage extends StatelessWidget {
  const FavoritesPage({
    super.key,
    required this.favorites,
    required this.onToggleFavorite,
    required this.onAddToTrip,
  });

  final List<Destination> favorites;
  final ValueChanged<Destination> onToggleFavorite;
  final ValueChanged<Destination> onAddToTrip;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        const Text(
          'Your favourite places',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: travelText,
          ),
        ),
        const SizedBox(height: 5),
        const Text(
          'Keep the places you want to visit in one convenient list.',
          style: TextStyle(color: Colors.black54),
        ),
        const SizedBox(height: 16),
        if (favorites.isEmpty)
          const _EmptyState(
            icon: Icons.favorite_border,
            title: 'No favourites yet',
            message: 'Tap the heart on an attraction to save it here.',
          )
        else
          ...favorites.map(
                (destination) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: DestinationCard(
                destination: destination,
                isFavorite: true,
                onToggleFavorite: () => onToggleFavorite(destination),
                onAddToTrip: () => onAddToTrip(destination),
                onTap: () => _showDetails(context, destination),
              ),
            ),
          ),
      ],
    );
  }
}

class TripPlannerPage extends StatelessWidget {
  const TripPlannerPage({
    super.key,
    required this.tripName,
    required this.budget,
    required this.stops,
    required this.onEditTrip,
    required this.onEditBudget,
    required this.onAddDestination,
    required this.onRemoveStop,
  });

  final String tripName;
  final double budget;
  final List<PlannedStop> stops;
  final VoidCallback onEditTrip;
  final VoidCallback onEditBudget;
  final VoidCallback onAddDestination;
  final ValueChanged<PlannedStop> onRemoveStop;

  @override
  Widget build(BuildContext context) {
    final plannedCost = stops.length * 35.0;
    final budgetProgress = budget <= 0
        ? 0.0
        : (plannedCost / budget).clamp(0.0, 1.0).toDouble();

    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 20),
      children: [
        InkWell(
          onTap: onEditTrip,
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '\u2018$tripName\u2019',
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Icon(Icons.edit_outlined, size: 19, color: Colors.black54),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${_formatDate(DateTime.now().add(const Duration(days: 3)))} - '
              '${_formatDate(DateTime.now().add(const Duration(days: 5)))}',
          style: const TextStyle(color: Colors.black54, fontSize: 12),
        ),
        const SizedBox(height: 16),
        InkWell(
          onTap: onEditBudget,
          child: Row(
            children: [
              const Text(
                'Budget:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 8),
              Text(
                '\$${plannedCost.toStringAsFixed(0)} / \$${budget.toStringAsFixed(0)}',
                style: const TextStyle(fontSize: 13),
              ),
              const Spacer(),
              const Icon(Icons.edit_outlined, size: 17, color: Colors.black54),
            ],
          ),
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: budgetProgress,
            minHeight: 13,
            backgroundColor: Colors.grey.shade300,
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF18E99A)),
          ),
        ),
        const Divider(height: 28),
        const Text(
          'Planned Destinations',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        if (stops.isEmpty)
          const _EmptyState(
            icon: Icons.map_outlined,
            title: 'No destinations planned',
            message: 'Add attractions to start building your trip.',
          )
        else
          ...stops.map(
                (stop) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: PlannedStopCard(
                stop: stop,
                onRemove: () => onRemoveStop(stop),
              ),
            ),
          ),
        const SizedBox(height: 4),
        OutlinedButton(
          onPressed: onAddDestination,
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.black54,
            side: const BorderSide(color: Colors.black26),
            backgroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 13),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          child: const Text('[ Add Destination ]'),
        ),
      ],
    );
  }
}

class DestinationCard extends StatelessWidget {
  const DestinationCard({
    super.key,
    required this.destination,
    required this.isFavorite,
    required this.onToggleFavorite,
    required this.onAddToTrip,
    required this.onTap,
  });

  final Destination destination;
  final bool isFavorite;
  final VoidCallback onToggleFavorite;
  final VoidCallback onAddToTrip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: 2.25,
                  child: Image.network(
                    destination.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: const Color(0xFFD8EDF0),
                      child: const Center(
                        child: Icon(
                          Icons.photo_outlined,
                          size: 44,
                          color: travelCyan,
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: 8,
                  top: 8,
                  child: Material(
                    color: Colors.white.withValues(alpha: 0.94),
                    shape: const CircleBorder(),
                    child: IconButton(
                      onPressed: onToggleFavorite,
                      tooltip: isFavorite
                          ? 'Remove from favourites'
                          : 'Add to favourites',
                      icon: Icon(
                        isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: isFavorite ? Colors.redAccent : travelCyan,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    destination.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      Text(
                        destination.rating.toStringAsFixed(1),
                        style: const TextStyle(color: Colors.black54),
                      ),
                      const SizedBox(width: 3),
                      const Icon(Icons.star, color: Colors.amber, size: 17),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.location_on_outlined,
                        color: travelCyan,
                        size: 17,
                      ),
                      Flexible(
                        child: Text(
                          '${destination.distance} · ${destination.location}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.black54,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.circle, color: Color(0xFF19D879), size: 9),
                      const SizedBox(width: 5),
                      Text(
                        'Currently: ${destination.activity}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: onAddToTrip,
                        tooltip: 'Add to trip',
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(
                          Icons.calendar_month_outlined,
                          color: travelCyan,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PlannedStopCard extends StatelessWidget {
  const PlannedStopCard({
    super.key,
    required this.stop,
    required this.onRemove,
  });

  final PlannedStop stop;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final destination = stop.destination;
    return Card(
      margin: EdgeInsets.zero,
      child: Row(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.horizontal(
              left: Radius.circular(4),
            ),
            child: SizedBox(
              width: 92,
              height: 112,
              child: Image.network(
                destination.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: const Color(0xFFD8EDF0),
                  child: const Icon(Icons.photo_outlined, color: travelCyan),
                ),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 2, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.place, color: Colors.orange, size: 18),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          destination.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(destination.rating.toStringAsFixed(1)),
                      const Icon(Icons.star, color: Colors.amber, size: 16),
                      const Spacer(),
                      Text(
                        _formatDate(stop.dateTime),
                        style: const TextStyle(fontSize: 11, color: Colors.black54),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_formatTime(stop.dateTime)} · ${destination.distance}',
                    style: const TextStyle(fontSize: 11, color: Colors.black54),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            onPressed: onRemove,
            tooltip: 'Remove destination',
            icon: const Icon(Icons.close, size: 18, color: Colors.black45),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 38, horizontal: 18),
      child: Column(
        children: [
          Icon(icon, size: 48, color: Colors.black26),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.black54),
          ),
        ],
      ),
    );
  }
}

void _showDetails(BuildContext context, Destination destination) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetContext) => SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 4, 18, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(5),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Image.network(
                  destination.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: const Color(0xFFD8EDF0),
                    child: const Icon(Icons.photo_outlined, size: 48),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              destination.name,
              style: const TextStyle(fontSize: 23, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 5),
            Text(
              '${destination.rating} ★  ·  ${destination.distance}  ·  ${destination.location}',
              style: const TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 14),
            Text(destination.description),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.circle, color: Color(0xFF19D879), size: 10),
                const SizedBox(width: 6),
                Text('Currently: ${destination.activity}'),
                const Spacer(),
                Text(
                  destination.hours,
                  style: const TextStyle(fontSize: 11, color: Colors.black54),
                ),
              ],
            ),
            const SizedBox(height: 18),
            const Text(
              'Reviews',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Reviews and live information can be connected to the API in a later milestone.',
              style: TextStyle(color: Colors.black54),
            ),
          ],
        ),
      ),
    ),
  );
}

String _formatDate(DateTime date) {
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];
  return '${months[date.month - 1]} ${date.day}';
}

String _formatTime(DateTime date) {
  final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
  final minute = date.minute.toString().padLeft(2, '0');
  final period = date.hour >= 12 ? 'PM' : 'AM';
  return '$hour:$minute $period';
}
