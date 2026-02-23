import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';

Widget buildTextField({
  required TextEditingController controller,
  required BuildContext context,
  required String labelText,
  String? hintText,
  required IconData icon,
  TextInputType keyboardType = TextInputType.text,
  int maxLines = 1,
  bool readOnly = false, // <-- Added
  FormFieldValidator<String>? validator,
  List<TextInputFormatter>? inputFormatters,
}) {
  return Container(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [
          Color(0xFF0A2A5A), // Deep navy blue
          Color(0xFF15489C), // Strong steel blue
          Color(0xFF1E64D8), // Vivid rich blue
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: Colors.blue.shade900.withOpacity(0.2),
          blurRadius: 10,
          offset: Offset(0, 4),
        ),
      ],
    ),
    padding: EdgeInsets.symmetric(horizontal: 8),
    child: TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textInputAction: TextInputAction.next,
      inputFormatters: inputFormatters,
      onEditingComplete: () => FocusScope.of(context).nextFocus(),
      maxLines: maxLines,
      readOnly: readOnly, // <-- Applied here
      style: TextStyle(
        fontSize: 16,
        color: Colors.cyan.shade100,
      ),
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
        hintText: hintText,
        hintStyle: TextStyle(
          color: Colors.cyan.shade300,
        ),
        prefixIcon: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Icon(icon, color: Colors.white),
        ),
        filled: true,
        fillColor: Colors.transparent,
        border: InputBorder.none,
        contentPadding: EdgeInsets.all(10),
      ),
      validator: validator,
    ),
  );
}


Widget buildLeaveField({
  required TextEditingController controller,
  required String labelText,
  required BuildContext context,
  String? hintText,
  required IconData icon,
  TextInputType keyboardType = TextInputType.text,
  int maxLines = 1,
  bool readOnly = false,
  VoidCallback? onTap,
  FormFieldValidator<String>? validator,
}) {
  return Container(
    margin: const EdgeInsets.symmetric(vertical: 8),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [
          Color(0xFF0A2A5A), // Deep navy blue
          Color(0xFF15489C), // Strong steel blue
          Color(0xFF1E64D8), // Vivid rich blue
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: Colors.blue.shade900.withOpacity(0.2),
          blurRadius: 10,
          offset: Offset(0, 4),
        ),
      ],
    ),
    padding: const EdgeInsets.symmetric(horizontal: 8),
    child: TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textInputAction: TextInputAction.next,
      onEditingComplete: () => FocusScope.of(context).nextFocus(),
      maxLines: maxLines,
      readOnly: readOnly,
      onTap: onTap,
      style: TextStyle(
        fontSize: 16,
        color: Colors.cyan.shade100,
      ),
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
        hintText: hintText,
        hintStyle: TextStyle(
          color: Colors.cyan.shade300,
        ),
        prefixIcon: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Icon(icon, color: Colors.white),
        ),
        filled: true,
        fillColor: Colors.transparent,
        border: InputBorder.none,
        contentPadding: const EdgeInsets.all(10),
      ),
      validator: validator,
    ),
  );
}

Widget buildDropdownField({
  required BuildContext context,
  required String labelText,
  required IconData icon,
  required String? value,
  required List<Map<String, dynamic>> items,
  required ValueChanged<String?> onChanged,
  FormFieldValidator<String>? validator,
  FocusNode? focusNode,
}) {
  // Extract all dropdown values
  final dropdownValues = items.map((e) => e['text'] as String).toSet();

  // ✅ Defensive: Ensure the currently selected value is valid
  final dropdownValue = (value != null && dropdownValues.contains(value))
      ? value
      : null; // <- Avoids assertion error

  return Container(
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [
          Color(0xFF0A2A5A),
          Color(0xFF15489C),
          Color(0xFF1E64D8),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: Colors.blue.shade900.withOpacity(0.2),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    padding: const EdgeInsets.symmetric(horizontal: 8),
    child: Focus(
      focusNode: focusNode,
      child: DropdownButtonFormField<String>(
        value: dropdownValue,
        iconEnabledColor: Colors.white,
        style: const TextStyle(fontSize: 16, color: Colors.white),
        decoration: InputDecoration(
          labelText: labelText,
          prefixIcon: Icon(icon, color: Colors.white),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(10),
          labelStyle: const TextStyle(color: Colors.white),
        ),
        dropdownColor: const Color(0xFF0A2A5A),
        isExpanded: true,
        items: items.map((item) {
          return DropdownMenuItem<String>(
            value: item['text'],
            child: Row(
              children: [
                Icon(item['icon'], color: Colors.cyanAccent),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    item['text'],
                    style: const TextStyle(color: Colors.cyanAccent),
                    overflow: TextOverflow.ellipsis,
                    softWrap: true,
                    maxLines: 2,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
        onChanged: (val) {
          onChanged(val);
          FocusScope.of(context).nextFocus();
        },
        validator: validator,
      ),
    ),
  );
}
Widget buildMultiSelectDropdownField({
  required BuildContext context,
  required String labelText,
  required IconData icon,
  required List<String> items,
  required List<String> selectedItems,
  required ValueChanged<List<String>> onChanged,
  FocusNode? nextFocus,
}) {
  return Container(
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [
          Color(0xFF0A2A5A),
          Color(0xFF15489C),
          Color(0xFF1E64D8),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: Colors.blue.shade900.withOpacity(0.2),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: DropdownSearch<String>.multiSelection(
      items: items,
      selectedItems: selectedItems,
      onChanged: (newList) {
        onChanged(newList);
        if (nextFocus != null) {
          FocusScope.of(context).requestFocus(nextFocus);
        } else {
          FocusScope.of(context).nextFocus(); // fallback
        }
      },
      popupProps: PopupPropsMultiSelection.menu(
        showSearchBox: true,
        itemBuilder: (context, item, isSelected) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Text(
            item,
            style: const TextStyle(color: Colors.white),
          ),
        ),
        searchFieldProps: TextFieldProps(
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(
            hintText: "Search employees...",
            hintStyle: const TextStyle(color: Colors.white70),
            prefixIcon: const Icon(Icons.search, color: Colors.white),
            border: UnderlineInputBorder(
              borderSide: const BorderSide(color: Colors.white),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          style: const TextStyle(color: Colors.white),
        ),
        menuProps: MenuProps(
          backgroundColor: Colors.blue.shade800,
          elevation: 8,
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      dropdownBuilder: (context, selectedItems) {
        return Text(
          selectedItems.join(', '),
          style: const TextStyle(color: Colors.white), // selected text
        );
      },
      dropdownDecoratorProps: DropDownDecoratorProps(
        dropdownSearchDecoration: InputDecoration(
          labelText: labelText,
          labelStyle: const TextStyle(color: Colors.white),
          prefixIcon: Icon(icon, color: Colors.white),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(10),
        ),
        baseStyle: const TextStyle(color: Colors.white),
      ),
      dropdownButtonProps: const DropdownButtonProps(
        icon: Icon(Icons.arrow_drop_down, color: Colors.white),
      ),
    ),
  );
}

Widget buildSection(String title, List<Widget> children) {
  return Card(
    elevation: 12,
    shadowColor: Colors.blue.shade900,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    color: Colors.white,
    child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.label, color: Colors.blue.shade900),
              const SizedBox(width: 8),
              Expanded(
                child: ShaderMask(
                  blendMode: BlendMode.srcIn,
                  shaderCallback: (bounds) {
                    return LinearGradient(
                      colors: [Colors.blue.shade900, Colors.blue.shade400],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ).createShader(bounds);
                  },
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children, // Fields go here — they must implement focus logic
        ],
      ),
    ),
  );
}

Widget buildDatePickerField(
    BuildContext context, {
      required String label,
      DateTime? date,
      required VoidCallback onTap,
      FormFieldValidator<String>? validator,
    }) {
  return GestureDetector(
    onTap: onTap,
    child: AbsorbPointer(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade900, Colors.blue.shade900],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.shade900.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: TextFormField(
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: label,
            labelStyle: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
            hintText: date == null
                ? "Pick a Date"
                : DateFormat('dd MMMM yyyy').format(date),
            hintStyle: TextStyle(color: Colors.cyan.shade300),
            filled: true,
            fillColor: Colors.transparent,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.all(16),
            prefixIcon: const Icon(Icons.calendar_today, color: Colors.white),
          ),
          controller: TextEditingController(
            text: date == null ? '' : DateFormat('dd MMMM yyyy').format(date),
          ),
          validator: validator,
          textInputAction: TextInputAction.next, // ✅ Added
          onEditingComplete: () => FocusScope.of(context).nextFocus(), // ✅ Added
        ),
      ),
    ),
  );
}

Widget buildTimePickerField(
    BuildContext context, {
      required String label,
      TimeOfDay? time,
      required VoidCallback onTap,
      FormFieldValidator<String>? validator,
    }) {
  return GestureDetector(
    onTap: onTap,
    child: AbsorbPointer(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade900, Colors.blue.shade900],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.shade900.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: TextFormField(
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: label,
            labelStyle: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
            hintText: time == null
                ? "Pick a Time"
                : MaterialLocalizations.of(context).formatTimeOfDay(
              time,
              alwaysUse24HourFormat: false,
            ),
            hintStyle: TextStyle(color: Colors.cyan.shade300),
            filled: true,
            fillColor: Colors.transparent,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.all(16),
            prefixIcon: const Icon(Icons.access_time, color: Colors.white),
          ),
          controller: TextEditingController(
            text: time == null
                ? ''
                : MaterialLocalizations.of(context).formatTimeOfDay(
              time,
              alwaysUse24HourFormat: false,
            ),
          ),
          validator: validator,
          textInputAction: TextInputAction.next,
          onEditingComplete: () => FocusScope.of(context).nextFocus(),
        ),
      ),
    ),
  );
}
Widget buildCustomCheckboxTile({
  required String title,
  required bool value,
  required ValueChanged<bool?> onChanged,
  required IconData icon,
  required Color color,
  FocusNode? focusNode,
  FocusNode? nextFocusNode,
}) {
  return Focus(
    focusNode: focusNode,
    child: Card(
      elevation: 6,
      shadowColor: Colors.cyan.shade300.withOpacity(0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.blue.shade900.withOpacity(0.1),
              Colors.blue.shade700.withOpacity(0.03),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: CheckboxListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          value: value,
          onChanged: (val) {
            onChanged(val);
            if (nextFocusNode != null) {
              nextFocusNode.requestFocus();
            }
          },
          activeColor: Colors.blue.shade900,
          checkColor: Colors.white,
          controlAffinity: ListTileControlAffinity.leading,
          title: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.blue.shade800,
                ),
                padding: const EdgeInsets.all(6),
                margin: const EdgeInsets.only(top: 2),
                child: Icon(icon, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded( // Ensures long text wraps responsively
                child: Text(
                  title,
                  softWrap: true,
                  overflow: TextOverflow.visible,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade900,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}


Widget buildCheckboxField({
  required BuildContext context,
  required String label,
  required bool value,
  required ValueChanged<bool?> onChanged,
}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 10.0),
    child: Focus(
      child: Builder(builder: (ctx) {
        return InkWell(
          onTap: () {
            onChanged(!value);
            FocusScope.of(context).nextFocus(); // Move focus manually
          },
          borderRadius: BorderRadius.circular(12),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: 40,
                width: 40,
                decoration: BoxDecoration(
                  color: value ? Colors.blue : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: value ? Colors.blue.shade800 : Colors.grey.shade400,
                    width: 2,
                  ),
                  boxShadow: value
                      ? [
                    BoxShadow(
                      color: Colors.blue.shade400.withOpacity(0.6),
                      spreadRadius: 2,
                      blurRadius: 6,
                    )
                  ]
                      : [],
                ),
                child: Icon(
                  value ? Icons.check : Icons.check_box_outline_blank,
                  color: value ? Colors.white : Colors.grey.shade600,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
            ],
          ),
        );
      }),
    ),
  );
}


// Validator for client's full name
FormFieldValidator<String> clientNameValidator = (value) {
  if (value == null || value.isEmpty) {
    return 'Please enter the client\'s name';
  }
  return null;
};
FormFieldValidator<String> typeOfPropertyValidator = (value){
  if(value==null|| value.isEmpty){
    return'Please select the Property Type';
  }
};
FormFieldValidator<String> additionalDetails = (value){
  if(value==null|| value.isEmpty){
    return'Fill out the necessary details which is required';
  }
};
FormFieldValidator<String> currentHomeAutomation = (value){
  if(value==null|| value.isEmpty){
    return'Select the type of which type of automation you want';
  }
};

// Validator for client's phone number
FormFieldValidator<String> phoneNumberValidator = (value) {
  // Check if the value is empty
  if (value == null || value.isEmpty) {
    return 'Please enter the phone number';
  }
  // Check if the value contains only digits and has exactly 10 digits
  else if (!RegExp(r'^\d{10}$').hasMatch(value)) {
    return 'Please enter a valid 10-digit phone number';
  }
  return null;
};

// Validator for appointment date
FormFieldValidator<DateTime> appointmentDateValidator = (value) {
  if (value == null) {
    return 'Please select an appointment date';
  }
  return null;
};

// Validator for appointment time
FormFieldValidator<TimeOfDay> appointmentTimeValidator = (value) {
  if (value == null) {
    return 'Please select an appointment time';
  }
  return null;
};

// Validator for meeting purpose
FormFieldValidator<String> meetingPurposeValidator = (value) {
  if (value == null) {
    return 'Please select a meeting purpose';
  }
  return null;
};

// Validator for meeting location
FormFieldValidator<String> meetingLocationValidator = (value) {
  if (value == null || value.isEmpty) {
    return 'Please enter the meeting location';
  }
  return null;
};

// Validator for assigned staff/CEO
FormFieldValidator<String> assignedStaffValidator = (value) {
  if (value == null) {
    return 'Please select assigned staff';
  }
  return null;
};

// Validator for task priority
FormFieldValidator<String> taskPriorityValidator = (value) {
  if (value == null) {
    return 'Please select task priority';
  }
  return null;
};
// Validator for Task Due Date
FormFieldValidator<String> taskDueDateValidator = (value) {
  if (value == null || value.isEmpty) {
    return 'Please select a task due date';
  }
  return null;
};


// Validator for Task Status
FormFieldValidator<String> taskStatusValidator = (value) {
  if (value == null) {
    return 'Please select a task status';
  }
  return null;
};


// Validator for Client Meeting Status
FormFieldValidator<String> clientMeetingStatusValidator = (value) {
  if (value == null) {
    return 'Please select the client meeting status';
  }
  return null;
};

////////////////////////////////////////////////////////////////////////////////////
//Sales page validators/////

class FieldValidators {
  // Full Name Validator
  static String? validateFullName(String? value) {
    if (value == null || value.isEmpty) {

      return 'Full Name is required';
    }
    return null;
  }

  // Contact Number Validator
  static String? validateContactNumber(String? value) {
    if (value == null || value.isEmpty) {

      return 'Please enter the phone number';
    }
    // Check if the value contains only digits and has exactly 10 digits
    else if (!RegExp(r'^\d{10}$').hasMatch(value)) {
      return 'Please enter a valid 10-digit phone number';
    }
    return null;
  }

  // Email Validator
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {

      return 'Email is required';
    }
    // Simple regex to check for a valid email format
    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
      return 'Enter a valid email address';
    }
    return null;
  }

  // Preferred Contact Method Validator
  static String? validatePreferredContactMethod(String? value) {
    if (value == null) {

      return 'Preferred contact method is required';
    }
    return null;
  }

  // Lead Source Validator
  static String? validateLeadSource(String? value) {
    if (value == null) {

      return 'Lead Source is required';
    }
    return null;
  }

  // Lead Type Validator
  static String? validateLeadType(String? value) {
    if (value == null) {

      return 'Lead Type is required';
    }
    return null;
  }

  // Property Size Validator
  static String? validatePropertySize(String? value) {
    if (value == null || value.isEmpty) {

      return 'Property size is required';
    }
    return null;
  }

  // Budget Range Validator
  static String? validateBudgetRange(String? value) {
    if (value == null) {

      return 'Budget range is required';
    }
    return null;
  }
}

//Task report page validators
String? validateEmployeeName(String? value) {
  if (value == null || value.isEmpty) {
    return 'Please enter your name';
  }
  return null;
}

String? validateTaskTitle(String? value) {
  if (value == null || value.isEmpty) {
    return 'Please enter the task title';
  }
  return null;
}

String? validateTaskDescription(String? value) {
  if (value == null || value.isEmpty) {
    return 'Please enter the task description';
  }
  return null;
}

String? validateHoursWorked(String? value) {
  if (value == null || value.isEmpty) {
    return 'Please enter the hours worked';
  }
  if (int.tryParse(value) == null) {
    return 'Please enter a valid number';
  }
  return null;
}

String? validateActionsTaken(String? value) {
  if (value == null || value.isEmpty) {
    return 'Please enter actions taken';
  }
  return null;
}

String? validateNextSteps(String? value) {
  if (value == null || value.isEmpty) {
    return 'Please enter next steps';
  }
  return null;
}

String? validateLocation(String? value) {
  if (value == null || value.isEmpty) {
    return 'Please enter a location';
  }
  return null;
}