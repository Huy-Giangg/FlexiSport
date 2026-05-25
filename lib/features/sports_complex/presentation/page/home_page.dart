import 'package:flexisport_app/features/sports_complex/presentation/providers/sports_complex_provider.dart';
import 'package:flexisport_app/features/sports_complex/presentation/widgets/sport_field_card.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';


class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {

  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      context.read<SportsComplexProvider>()
          .fetchStadiums();
    });
  }

  @override
  Widget build(BuildContext context) {

    final provider = context.watch<SportsComplexProvider>();

    if (provider.isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (provider.errorMessage != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("Stadiums"),
        ),
        body: Center(
          child: Text(
            provider.errorMessage!,
            style: const TextStyle(color: Colors.red),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Stadiums"),
      ),

      body: ListView.builder(
        itemCount: provider.stadiums.length,
        itemBuilder: (context, index) {

          final stadium = provider.stadiums[index];

          return SportFieldCard(sportsComplexEntity: stadium,);
        },
      ),
    );
  }
}