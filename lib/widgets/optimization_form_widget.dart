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
    return GestureDetector(
      onTap: () {
        // Dismiss keyboard when tapping outside of text fields
        FocusScope.of(context).unfocus();
      },
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildCriteriaSection(),
            const SizedBox(height: 20),
            _buildConstraintsSection(),
            const SizedBox(height: 20),
            _buildRestaurantInfoSection(),
            const SizedBox(height: 20),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.orange[600]!, Colors.orange[700]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.orange.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: _submitForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.settings_rounded, size: 20),
                    const SizedBox(width: 8),
                    const Text(
                      'Set Optimization Criteria',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRestaurantInfoSection() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ?? Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.amber[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.store_rounded,
                    color: Colors.amber[700],
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Restaurant Information',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[800],
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardTheme.color ?? Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Optional',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _restaurantNameController,
              decoration: InputDecoration(
                labelText: 'Restaurant Name',
                hintText: 'e.g., McDonald\'s, Chipotle',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Theme.of(context).cardTheme.color ?? Colors.grey[50],
                prefixIcon: Icon(Icons.restaurant_rounded, color: Colors.grey[500]),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _restaurantLocationController,
              decoration: InputDecoration(
                labelText: 'Location',
                hintText: 'e.g., New York, NY',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Theme.of(context).cardTheme.color ?? Colors.grey[50],
                prefixIcon: Icon(Icons.location_on_rounded, color: Colors.grey[500]),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _websiteController,
              decoration: InputDecoration(
                labelText: 'Website URL',
                hintText: 'https://example.com',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Theme.of(context).cardTheme.color ?? Colors.grey[50],
                prefixIcon: Icon(Icons.language_rounded, color: Colors.grey[500]),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ?? Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.purple[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.psychology_rounded,
                    color: Colors.purple[600],
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Optimization Goals',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[800],
                    ),
                  ),
                ),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _addCriteria,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.add_rounded,
                        color: Colors.green[600],
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ..._criteria.map((criteria) => _buildCriteriaItem(criteria)),
          ],
        ),
      ),
    );
  }

  Widget _buildCriteriaItem(CriteriaItem criteria) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ?? Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row with Icon and Delete Button
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.purple[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.track_changes_rounded,
                    color: Colors.purple[600],
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Optimization Goal',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[800],
                      fontSize: 16,
                    ),
                  ),
                ),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _removeCriteria(criteria),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.delete_outline_rounded,
                        color: Colors.red[600],
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Dropdown on separate line
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardTheme.color ?? Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!, width: 1),
              ),
              child: DropdownButtonFormField<CriteriaOption>(
                initialValue: criteria.option,
                decoration: const InputDecoration(
                  labelText: 'Select Goal',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                isExpanded: true,
                items: _availableCriteria.map((option) {
                  return DropdownMenuItem(
                    value: option,
                    child: Text(
                      option.displayName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    criteria.option = value!;
                  });
                },
              ),
            ),
            const SizedBox(height: 16),

            // Description
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!, width: 1),
              ),
              child: Text(
                criteria.option.description,
                style: TextStyle(
                  color: Colors.blue[700],
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Weight Slider Section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green[200]!, width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.tune_rounded, color: Colors.green[600], size: 18),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'Importance Weight',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.green[700],
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          criteria.weight.toStringAsFixed(1),
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: Colors.green[700],
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: Colors.green[400],
                      inactiveTrackColor: Colors.green[200],
                      thumbColor: Colors.green[600],
                      overlayColor: Colors.green[200]?.withValues(alpha: 0.3),
                      trackHeight: 6.0,
                    ),
                    child: Slider(
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
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Low (0.1)',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        'High (2.0)',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Goal Toggle Section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange[200]!, width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.flag_rounded, color: Colors.orange[600], size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'Optimization Goal',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.orange[700],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardTheme.color ?? Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange[200]!, width: 1),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                criteria.isMaximize = true;
                              });
                            },
                            child: Container(
                              height: 44,
                              decoration: BoxDecoration(
                                color: criteria.isMaximize ? Colors.orange[500] : (Theme.of(context).cardTheme.color ?? Colors.white),
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(8),
                                  bottomLeft: Radius.circular(8),
                                ),
                                border: Border.all(color: Colors.orange[300]!, width: 1),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.trending_up_rounded,
                                    size: 16,
                                    color: criteria.isMaximize ? Colors.white : Colors.orange[600],
                                  ),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      'Max',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12,
                                        color: criteria.isMaximize ? Colors.white : Colors.orange[600],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                criteria.isMaximize = false;
                              });
                            },
                            child: Container(
                              height: 44,
                              decoration: BoxDecoration(
                                color: !criteria.isMaximize ? Colors.orange[500] : (Theme.of(context).cardTheme.color ?? Colors.white),
                                borderRadius: const BorderRadius.only(
                                  topRight: Radius.circular(8),
                                  bottomRight: Radius.circular(8),
                                ),
                                border: Border.all(color: Colors.orange[300]!, width: 1),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.trending_down_rounded,
                                    size: 16,
                                    color: !criteria.isMaximize ? Colors.white : Colors.orange[600],
                                  ),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      'Min',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12,
                                        color: !criteria.isMaximize ? Colors.white : Colors.orange[600],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConstraintsSection() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ?? Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.filter_alt_rounded,
                    color: Colors.red[600],
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Dietary Constraints',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[800],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardTheme.color ?? Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!, width: 1),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.attach_money, color: Colors.green[600], size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Budget',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[700],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _maxPriceController,
                      decoration: InputDecoration(
                        labelText: 'Maximum Price',
                        hintText: '15.00',
                        prefixText: '\$',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        filled: true,
                        fillColor: Theme.of(context).cardTheme.color ?? Colors.white,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                        suffixIcon: Container(
                          margin: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.green[600],
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.check_rounded, color: Colors.white, size: 20),
                            onPressed: () {
                              FocusScope.of(context).unfocus();
                            },
                            tooltip: 'Done',
                          ),
                        ),
                      ),
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) {
                        FocusScope.of(context).unfocus();
                      },
                      validator: (value) {
                        if (value != null && value.isNotEmpty) {
                          if (double.tryParse(value) == null) {
                            return 'Please enter a valid price';
                          }
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange[200]!, width: 1),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.warning_rounded, color: Colors.orange[600], size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Allergen Restrictions',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[700],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _availableAllergens.map((allergen) {
                        bool isSelected = _selectedAllergens.contains(allergen);
                        return FilterChip(
                          label: Text(
                            allergen,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          selected: isSelected,
                          selectedColor: Colors.orange[200],
                          backgroundColor: Theme.of(context).cardTheme.color ?? Colors.white,
                          side: BorderSide(
                            color: isSelected ? Colors.orange[400]! : Colors.grey[300]!,
                            width: 1,
                          ),
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
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue[200]!, width: 1),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.eco_rounded, color: Colors.blue[600], size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Dietary Preferences',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[700],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _availableDietaryRestrictions.map((restriction) {
                        bool isSelected = _selectedDietaryRestrictions.contains(restriction);
                        return FilterChip(
                          label: Text(
                            restriction,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          selected: isSelected,
                          selectedColor: Colors.blue[200],
                          backgroundColor: Theme.of(context).cardTheme.color ?? Colors.white,
                          side: BorderSide(
                            color: isSelected ? Colors.blue[400]! : Colors.grey[300]!,
                            width: 1,
                          ),
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