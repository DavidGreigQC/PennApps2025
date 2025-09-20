import 'package:flutter/material.dart';
import '../models/optimization_criteria.dart';

class OptimizationFormWidget extends StatefulWidget {
  final Function(OptimizationRequest) onOptimizationRequest;

  const OptimizationFormWidget({
    super.key,
    required this.onOptimizationRequest,
  });

  @override
  State<OptimizationFormWidget> createState() => _OptimizationFormWidgetState();
}

class _OptimizationFormWidgetState extends State<OptimizationFormWidget> {
  final _formKey = GlobalKey<FormState>();
  final _restaurantNameController = TextEditingController();
  final _restaurantLocationController = TextEditingController();
  final _websiteController = TextEditingController();
  final _maxPriceController = TextEditingController();
  final _notesController = TextEditingController();

  final List<String> _selectedAllergens = [];
  final List<String> _selectedDietaryRestrictions = [];
  List<CriteriaItem> _criteria = [];

  final List<String> _availableAllergens = [
    'Nuts', 'Dairy', 'Gluten', 'Shellfish', 'Eggs', 'Soy', 'Fish'
  ];

  final List<String> _availableDietaryRestrictions = [
    'Vegetarian', 'Vegan', 'Keto', 'Low-carb', 'Low-sodium', 'Gluten-free'
  ];

  final List<CriteriaOption> _availableCriteria = [
    CriteriaOption('protein_per_dollar', 'Protein per Dollar', 'Maximize protein content relative to price'),
    CriteriaOption('calories_per_dollar', 'Calories per Dollar', 'Maximize calories relative to price'),
    CriteriaOption('health_score', 'Health Score', 'Maximize overall nutritional quality'),
    CriteriaOption('price', 'Low Price', 'Minimize cost'),
    CriteriaOption('protein', 'High Protein', 'Maximize protein content'),
    CriteriaOption('fiber', 'High Fiber', 'Maximize fiber content'),
    CriteriaOption('nutrient_density', 'Nutrient Density', 'Maximize nutrients per calorie'),
  ];

  @override
  void initState() {
    super.initState();
    _criteria = [
      CriteriaItem(_availableCriteria[0], 1.0, true),
      CriteriaItem(_availableCriteria[3], 0.5, false),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildRestaurantInfoSection(),
          const SizedBox(height: 16),
          _buildCriteriaSection(),
          const SizedBox(height: 16),
          _buildConstraintsSection(),
          const SizedBox(height: 16),
          _buildNotesSection(),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _submitForm,
            child: const Text('Set Optimization Criteria'),
          ),
        ],
      ),
    );
  }

  Widget _buildRestaurantInfoSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Restaurant Information (Optional)',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _restaurantNameController,
              decoration: const InputDecoration(
                labelText: 'Restaurant Name',
                hintText: 'e.g., McDonald\'s, Chipotle',
                border: OutlineInputBorder(),
              ),
              textInputAction: TextInputAction.done,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _restaurantLocationController,
              decoration: const InputDecoration(
                labelText: 'Location',
                hintText: 'e.g., New York, NY',
                border: OutlineInputBorder(),
              ),
              textInputAction: TextInputAction.done,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _websiteController,
              decoration: const InputDecoration(
                labelText: 'Website URL',
                hintText: 'https://example.com',
                border: OutlineInputBorder(),
              ),
              textInputAction: TextInputAction.done,
              validator: (value) {
                if (value != null && value.isNotEmpty) {
                  Uri? uri = Uri.tryParse(value);
                  if (uri == null || !uri.hasAbsolutePath) {
                    return 'Please enter a valid URL';
                  }
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCriteriaSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Optimization Criteria',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: _addCriteria,
                ),
              ],
            ),
            const SizedBox(height: 12),
            ..._criteria.map((criteria) => _buildCriteriaItem(criteria)),
          ],
        ),
      ),
    );
  }

  Widget _buildCriteriaItem(CriteriaItem criteria) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<CriteriaOption>(
                    initialValue: criteria.option,
                    decoration: const InputDecoration(
                      labelText: 'Criteria',
                      border: OutlineInputBorder(),
                    ),
                    items: _availableCriteria.map((option) {
                      return DropdownMenuItem(
                        value: option,
                        child: Text(option.displayName),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        criteria.option = value!;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => _removeCriteria(criteria),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              criteria.option.description,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Weight: ${criteria.weight.toStringAsFixed(1)}'),
                      Slider(
                        value: criteria.weight,
                        min: 0.1,
                        max: 2.0,
                        divisions: 19,
                        onChanged: (value) {
                          setState(() {
                            criteria.weight = value;
                          });
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  children: [
                    const Text('Goal'),
                    ToggleButtons(
                      isSelected: [criteria.isMaximize, !criteria.isMaximize],
                      onPressed: (index) {
                        setState(() {
                          criteria.isMaximize = index == 0;
                        });
                      },
                      children: const [
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: Text('Max'),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: Text('Min'),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConstraintsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Constraints (Optional)',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _maxPriceController,
              decoration: const InputDecoration(
                labelText: 'Maximum Price',
                hintText: '15.00',
                prefixText: '\$',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              validator: (value) {
                if (value != null && value.isNotEmpty) {
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid price';
                  }
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            Text(
              'Allergen Restrictions',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _availableAllergens.map((allergen) {
                bool isSelected = _selectedAllergens.contains(allergen);
                return FilterChip(
                  label: Text(allergen),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedAllergens.add(allergen);
                      } else {
                        _selectedAllergens.remove(allergen);
                      }
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            Text(
              'Dietary Restrictions',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _availableDietaryRestrictions.map((restriction) {
                bool isSelected = _selectedDietaryRestrictions.contains(restriction);
                return FilterChip(
                  label: Text(restriction),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedDietaryRestrictions.add(restriction);
                      } else {
                        _selectedDietaryRestrictions.remove(restriction);
                      }
                    });
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Additional Notes',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                hintText: 'Any specific preferences or requirements...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              textInputAction: TextInputAction.done,
            ),
          ],
        ),
      ),
    );
  }

  void _addCriteria() {
    if (_criteria.length < _availableCriteria.length) {
      setState(() {
        _criteria.add(CriteriaItem(_availableCriteria[2], 1.0, true));
      });
    }
  }

  void _removeCriteria(CriteriaItem criteria) {
    if (_criteria.length > 1) {
      setState(() {
        _criteria.remove(criteria);
      });
    }
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      List<OptimizationCriteria> optimizationCriteria = _criteria.map((item) {
        return OptimizationCriteria(
          name: item.option.key,
          weight: item.weight,
          isMaximize: item.isMaximize,
          description: item.option.description,
        );
      }).toList();

      OptimizationRequest request = OptimizationRequest(
        restaurantName: _restaurantNameController.text.isNotEmpty
            ? _restaurantNameController.text
            : null,
        restaurantLocation: _restaurantLocationController.text.isNotEmpty
            ? _restaurantLocationController.text
            : null,
        websiteUrl: _websiteController.text.isNotEmpty
            ? _websiteController.text
            : null,
        criteria: optimizationCriteria,
        maxPrice: _maxPriceController.text.isNotEmpty
            ? double.tryParse(_maxPriceController.text)
            : null,
        allergenRestrictions: _selectedAllergens.isNotEmpty
            ? _selectedAllergens
            : null,
        dietaryRestrictions: _selectedDietaryRestrictions.isNotEmpty
            ? _selectedDietaryRestrictions
            : null,
        additionalNotes: _notesController.text.isNotEmpty
            ? _notesController.text
            : null,
      );

      widget.onOptimizationRequest(request);
    }
  }

  @override
  void dispose() {
    _restaurantNameController.dispose();
    _restaurantLocationController.dispose();
    _websiteController.dispose();
    _maxPriceController.dispose();
    _notesController.dispose();
    super.dispose();
  }
}

class CriteriaOption {
  final String key;
  final String displayName;
  final String description;

  CriteriaOption(this.key, this.displayName, this.description);
}

class CriteriaItem {
  CriteriaOption option;
  double weight;
  bool isMaximize;

  CriteriaItem(this.option, this.weight, this.isMaximize);
}