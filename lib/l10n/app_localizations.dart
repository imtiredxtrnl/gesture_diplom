import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_uk.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('uk'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign Language App'**
  String get appTitle;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @register.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get register;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @sign_in.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get sign_in;

  /// No description provided for @sign_out.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get sign_out;

  /// No description provided for @no_account.
  ///
  /// In en, this message translates to:
  /// **'No account?'**
  String get no_account;

  /// No description provided for @create_account.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get create_account;

  /// No description provided for @confirm_password.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirm_password;

  /// No description provided for @enter_email_password.
  ///
  /// In en, this message translates to:
  /// **'Enter email and password'**
  String get enter_email_password;

  /// No description provided for @validation_all_fields_required.
  ///
  /// In en, this message translates to:
  /// **'All fields are required'**
  String get validation_all_fields_required;

  /// No description provided for @validation_passwords_do_not_match.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get validation_passwords_do_not_match;

  /// No description provided for @registration_in_progress.
  ///
  /// In en, this message translates to:
  /// **'Registration in progress...'**
  String get registration_in_progress;

  /// No description provided for @registration_success.
  ///
  /// In en, this message translates to:
  /// **'Registration successful!'**
  String get registration_success;

  /// No description provided for @registration_error.
  ///
  /// In en, this message translates to:
  /// **'Registration error'**
  String get registration_error;

  /// No description provided for @connection_error.
  ///
  /// In en, this message translates to:
  /// **'Connection error'**
  String get connection_error;

  /// No description provided for @connection_closed_before_response.
  ///
  /// In en, this message translates to:
  /// **'Connection closed before response'**
  String get connection_closed_before_response;

  /// No description provided for @connection_error_to_server.
  ///
  /// In en, this message translates to:
  /// **'Connection error to server'**
  String get connection_error_to_server;

  /// No description provided for @user_not_authorized.
  ///
  /// In en, this message translates to:
  /// **'User not authorized'**
  String get user_not_authorized;

  /// No description provided for @edit_profile.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get edit_profile;

  /// No description provided for @save_changes.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get save_changes;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @confirm_logout.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to logout?'**
  String get confirm_logout;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @reset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get reset;

  /// No description provided for @reset_progress.
  ///
  /// In en, this message translates to:
  /// **'Reset Progress'**
  String get reset_progress;

  /// No description provided for @confirm_reset_progress.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to reset your progress?'**
  String get confirm_reset_progress;

  /// No description provided for @progress_reset.
  ///
  /// In en, this message translates to:
  /// **'Progress reset!'**
  String get progress_reset;

  /// No description provided for @tests_completed.
  ///
  /// In en, this message translates to:
  /// **'Tests completed'**
  String get tests_completed;

  /// No description provided for @notes_completed.
  ///
  /// In en, this message translates to:
  /// **'Notes completed'**
  String get notes_completed;

  /// No description provided for @level.
  ///
  /// In en, this message translates to:
  /// **'Level'**
  String get level;

  /// No description provided for @beginner.
  ///
  /// In en, this message translates to:
  /// **'Beginner'**
  String get beginner;

  /// No description provided for @intermediate.
  ///
  /// In en, this message translates to:
  /// **'Intermediate'**
  String get intermediate;

  /// No description provided for @experienced.
  ///
  /// In en, this message translates to:
  /// **'Experienced'**
  String get experienced;

  /// No description provided for @expert.
  ///
  /// In en, this message translates to:
  /// **'Expert'**
  String get expert;

  /// No description provided for @statistics.
  ///
  /// In en, this message translates to:
  /// **'Statistics'**
  String get statistics;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @ukrainian.
  ///
  /// In en, this message translates to:
  /// **'Ukrainian'**
  String get ukrainian;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @not_authorized.
  ///
  /// In en, this message translates to:
  /// **'Not authorized'**
  String get not_authorized;

  /// No description provided for @please_login.
  ///
  /// In en, this message translates to:
  /// **'Please log in to continue'**
  String get please_login;

  /// No description provided for @tests.
  ///
  /// In en, this message translates to:
  /// **'Tests'**
  String get tests;

  /// No description provided for @test.
  ///
  /// In en, this message translates to:
  /// **'Test'**
  String get test;

  /// No description provided for @check_answer.
  ///
  /// In en, this message translates to:
  /// **'Check Answer'**
  String get check_answer;

  /// No description provided for @finish.
  ///
  /// In en, this message translates to:
  /// **'Finish'**
  String get finish;

  /// No description provided for @choose_correct_answer.
  ///
  /// In en, this message translates to:
  /// **'Choose the correct answer'**
  String get choose_correct_answer;

  /// No description provided for @correct.
  ///
  /// In en, this message translates to:
  /// **'Correct!'**
  String get correct;

  /// No description provided for @incorrect.
  ///
  /// In en, this message translates to:
  /// **'Incorrect'**
  String get incorrect;

  /// No description provided for @category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// No description provided for @completed.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completed;

  /// No description provided for @add_test.
  ///
  /// In en, this message translates to:
  /// **'Add Test'**
  String get add_test;

  /// No description provided for @edit_test.
  ///
  /// In en, this message translates to:
  /// **'Edit Test'**
  String get edit_test;

  /// No description provided for @delete_test.
  ///
  /// In en, this message translates to:
  /// **'Delete Test'**
  String get delete_test;

  /// No description provided for @confirm_delete_test.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this test?'**
  String get confirm_delete_test;

  /// No description provided for @search_tests.
  ///
  /// In en, this message translates to:
  /// **'Search tests...'**
  String get search_tests;

  /// No description provided for @options.
  ///
  /// In en, this message translates to:
  /// **'Options'**
  String get options;

  /// No description provided for @option.
  ///
  /// In en, this message translates to:
  /// **'Option'**
  String get option;

  /// No description provided for @answer_options.
  ///
  /// In en, this message translates to:
  /// **'Answer Options'**
  String get answer_options;

  /// No description provided for @validation_test_question.
  ///
  /// In en, this message translates to:
  /// **'Enter the test question'**
  String get validation_test_question;

  /// No description provided for @validation_option.
  ///
  /// In en, this message translates to:
  /// **'Enter the answer option'**
  String get validation_option;

  /// No description provided for @add_gesture.
  ///
  /// In en, this message translates to:
  /// **'Add Gesture'**
  String get add_gesture;

  /// No description provided for @edit_gesture.
  ///
  /// In en, this message translates to:
  /// **'Edit Gesture'**
  String get edit_gesture;

  /// No description provided for @delete_gesture.
  ///
  /// In en, this message translates to:
  /// **'Delete Gesture'**
  String get delete_gesture;

  /// No description provided for @confirm_delete_gesture.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this gesture?'**
  String get confirm_delete_gesture;

  /// No description provided for @delete_gesture_cannot_be_undone.
  ///
  /// In en, this message translates to:
  /// **'This action cannot be undone!'**
  String get delete_gesture_cannot_be_undone;

  /// No description provided for @gesture.
  ///
  /// In en, this message translates to:
  /// **'Gesture'**
  String get gesture;

  /// No description provided for @gestures.
  ///
  /// In en, this message translates to:
  /// **'Gestures'**
  String get gestures;

  /// No description provided for @gestures_dictionary.
  ///
  /// In en, this message translates to:
  /// **'Gestures Dictionary'**
  String get gestures_dictionary;

  /// No description provided for @gestures_dictionary_description.
  ///
  /// In en, this message translates to:
  /// **'Browse all available gestures'**
  String get gestures_dictionary_description;

  /// No description provided for @gestures_practice.
  ///
  /// In en, this message translates to:
  /// **'Practice Gestures'**
  String get gestures_practice;

  /// No description provided for @gestures_practice_description.
  ///
  /// In en, this message translates to:
  /// **'Practice recognizing and showing gestures'**
  String get gestures_practice_description;

  /// No description provided for @gestures_alphabet.
  ///
  /// In en, this message translates to:
  /// **'Alphabet'**
  String get gestures_alphabet;

  /// No description provided for @gestures_alphabet_description.
  ///
  /// In en, this message translates to:
  /// **'Learn the sign language alphabet'**
  String get gestures_alphabet_description;

  /// No description provided for @gestures_tests.
  ///
  /// In en, this message translates to:
  /// **'Tests'**
  String get gestures_tests;

  /// No description provided for @gestures_tests_description.
  ///
  /// In en, this message translates to:
  /// **'Test your knowledge of gestures'**
  String get gestures_tests_description;

  /// No description provided for @search_gestures.
  ///
  /// In en, this message translates to:
  /// **'Search gestures...'**
  String get search_gestures;

  /// No description provided for @loading_gestures.
  ///
  /// In en, this message translates to:
  /// **'Loading gestures...'**
  String get loading_gestures;

  /// No description provided for @no_gestures_found.
  ///
  /// In en, this message translates to:
  /// **'No gestures found'**
  String get no_gestures_found;

  /// No description provided for @no_gestures_in_category.
  ///
  /// In en, this message translates to:
  /// **'No gestures in this category'**
  String get no_gestures_in_category;

  /// No description provided for @try_again.
  ///
  /// In en, this message translates to:
  /// **'Try Again'**
  String get try_again;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @add_image.
  ///
  /// In en, this message translates to:
  /// **'Add Image'**
  String get add_image;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @main_info.
  ///
  /// In en, this message translates to:
  /// **'Main Info'**
  String get main_info;

  /// No description provided for @gesture_name.
  ///
  /// In en, this message translates to:
  /// **'Gesture Name'**
  String get gesture_name;

  /// No description provided for @gesture_description.
  ///
  /// In en, this message translates to:
  /// **'Gesture Description'**
  String get gesture_description;

  /// No description provided for @gesture_description_hint.
  ///
  /// In en, this message translates to:
  /// **'Describe the gesture...'**
  String get gesture_description_hint;

  /// No description provided for @validation_gesture_name.
  ///
  /// In en, this message translates to:
  /// **'Enter the gesture name'**
  String get validation_gesture_name;

  /// No description provided for @validation_gesture_name_length.
  ///
  /// In en, this message translates to:
  /// **'Gesture name is too short'**
  String get validation_gesture_name_length;

  /// No description provided for @validation_gesture_description.
  ///
  /// In en, this message translates to:
  /// **'Enter the gesture description'**
  String get validation_gesture_description;

  /// No description provided for @validation_gesture_description_length.
  ///
  /// In en, this message translates to:
  /// **'Description is too short'**
  String get validation_gesture_description_length;

  /// No description provided for @gesture_image.
  ///
  /// In en, this message translates to:
  /// **'Gesture Image'**
  String get gesture_image;

  /// No description provided for @gesture_image_hint.
  ///
  /// In en, this message translates to:
  /// **'Add a photo or illustration of the gesture'**
  String get gesture_image_hint;

  /// No description provided for @image_selected.
  ///
  /// In en, this message translates to:
  /// **'Image selected'**
  String get image_selected;

  /// No description provided for @change_image.
  ///
  /// In en, this message translates to:
  /// **'Change Image'**
  String get change_image;

  /// No description provided for @select_image.
  ///
  /// In en, this message translates to:
  /// **'Select Image'**
  String get select_image;

  /// No description provided for @image_not_selected.
  ///
  /// In en, this message translates to:
  /// **'Image not selected'**
  String get image_not_selected;

  /// No description provided for @click_button_below_to_select.
  ///
  /// In en, this message translates to:
  /// **'Click the button below to select an image'**
  String get click_button_below_to_select;

  /// No description provided for @create_gesture.
  ///
  /// In en, this message translates to:
  /// **'Create Gesture'**
  String get create_gesture;

  /// No description provided for @saving_gesture.
  ///
  /// In en, this message translates to:
  /// **'Saving gesture...'**
  String get saving_gesture;

  /// No description provided for @success_gesture_added.
  ///
  /// In en, this message translates to:
  /// **'Gesture added successfully!'**
  String get success_gesture_added;

  /// No description provided for @error_gesture_addition.
  ///
  /// In en, this message translates to:
  /// **'Error adding gesture'**
  String get error_gesture_addition;

  /// No description provided for @error_gesture_saving.
  ///
  /// In en, this message translates to:
  /// **'Error saving gesture'**
  String get error_gesture_saving;

  /// No description provided for @success_gesture_update.
  ///
  /// In en, this message translates to:
  /// **'Gesture updated successfully!'**
  String get success_gesture_update;

  /// No description provided for @error_gesture_update.
  ///
  /// In en, this message translates to:
  /// **'Error updating gesture'**
  String get error_gesture_update;

  /// No description provided for @error_gesture_save.
  ///
  /// In en, this message translates to:
  /// **'Error saving gesture'**
  String get error_gesture_save;

  /// No description provided for @error_image_selection.
  ///
  /// In en, this message translates to:
  /// **'Error selecting image'**
  String get error_image_selection;

  /// No description provided for @error_image_picker.
  ///
  /// In en, this message translates to:
  /// **'Error picking image'**
  String get error_image_picker;

  /// No description provided for @tip.
  ///
  /// In en, this message translates to:
  /// **'Tip'**
  String get tip;

  /// No description provided for @tip_description.
  ///
  /// In en, this message translates to:
  /// **'Use clear and high-quality images for best results.'**
  String get tip_description;

  /// No description provided for @add_letter.
  ///
  /// In en, this message translates to:
  /// **'Add Letter'**
  String get add_letter;

  /// No description provided for @edit_letter.
  ///
  /// In en, this message translates to:
  /// **'Edit Letter'**
  String get edit_letter;

  /// No description provided for @delete_letter.
  ///
  /// In en, this message translates to:
  /// **'Delete Letter'**
  String get delete_letter;

  /// No description provided for @letter.
  ///
  /// In en, this message translates to:
  /// **'Letter'**
  String get letter;

  /// No description provided for @letters.
  ///
  /// In en, this message translates to:
  /// **'Letters'**
  String get letters;

  /// No description provided for @alphabet.
  ///
  /// In en, this message translates to:
  /// **'Alphabet'**
  String get alphabet;

  /// No description provided for @ukrainian_alphabet.
  ///
  /// In en, this message translates to:
  /// **'Ukrainian Alphabet'**
  String get ukrainian_alphabet;

  /// No description provided for @ukrainian_alphabet_description.
  ///
  /// In en, this message translates to:
  /// **'Learn the Ukrainian sign language alphabet'**
  String get ukrainian_alphabet_description;

  /// No description provided for @english_alphabet.
  ///
  /// In en, this message translates to:
  /// **'English Alphabet'**
  String get english_alphabet;

  /// No description provided for @english_alphabet_description.
  ///
  /// In en, this message translates to:
  /// **'Learn the English sign language alphabet'**
  String get english_alphabet_description;

  /// No description provided for @select.
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get select;

  /// No description provided for @image_not_loaded_demo.
  ///
  /// In en, this message translates to:
  /// **'Image not loaded (demo)'**
  String get image_not_loaded_demo;

  /// No description provided for @add_first_gesture.
  ///
  /// In en, this message translates to:
  /// **'Add the first gesture'**
  String get add_first_gesture;

  /// No description provided for @admin_panel.
  ///
  /// In en, this message translates to:
  /// **'Admin Panel'**
  String get admin_panel;

  /// No description provided for @gestures_management.
  ///
  /// In en, this message translates to:
  /// **'Gestures Management'**
  String get gestures_management;

  /// No description provided for @gestures_management_desc.
  ///
  /// In en, this message translates to:
  /// **'Add, edit or delete gestures'**
  String get gestures_management_desc;

  /// No description provided for @tests_management.
  ///
  /// In en, this message translates to:
  /// **'Tests Management'**
  String get tests_management;

  /// No description provided for @tests_management_desc.
  ///
  /// In en, this message translates to:
  /// **'Add, edit or delete tests'**
  String get tests_management_desc;

  /// No description provided for @total_users.
  ///
  /// In en, this message translates to:
  /// **'Total users'**
  String get total_users;

  /// No description provided for @gestures_in_dict.
  ///
  /// In en, this message translates to:
  /// **'Gestures in dictionary'**
  String get gestures_in_dict;

  /// No description provided for @test_question.
  ///
  /// In en, this message translates to:
  /// **'Test Question'**
  String get test_question;

  /// No description provided for @success.
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get success;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @camera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get camera;

  /// No description provided for @initializing_camera.
  ///
  /// In en, this message translates to:
  /// **'Initializing camera...'**
  String get initializing_camera;

  /// No description provided for @camera_not_initialized.
  ///
  /// In en, this message translates to:
  /// **'Camera not initialized'**
  String get camera_not_initialized;

  /// No description provided for @initialize_camera.
  ///
  /// In en, this message translates to:
  /// **'Initialize Camera'**
  String get initialize_camera;

  /// No description provided for @recognized_gesture.
  ///
  /// In en, this message translates to:
  /// **'Recognized Gesture'**
  String get recognized_gesture;

  /// No description provided for @practice_with_camera.
  ///
  /// In en, this message translates to:
  /// **'Practice with Camera'**
  String get practice_with_camera;

  /// No description provided for @mark_as_learned.
  ///
  /// In en, this message translates to:
  /// **'Mark as Learned'**
  String get mark_as_learned;

  /// No description provided for @learned.
  ///
  /// In en, this message translates to:
  /// **'Learned!'**
  String get learned;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @follow_instructions.
  ///
  /// In en, this message translates to:
  /// **'Follow the instructions'**
  String get follow_instructions;

  /// No description provided for @practice_instruction.
  ///
  /// In en, this message translates to:
  /// **'Practice the gesture as shown'**
  String get practice_instruction;

  /// No description provided for @practice_step1.
  ///
  /// In en, this message translates to:
  /// **'Step 1: Position your hand in front of the camera'**
  String get practice_step1;

  /// No description provided for @practice_step2.
  ///
  /// In en, this message translates to:
  /// **'Step 2: Repeat the gesture'**
  String get practice_step2;

  /// No description provided for @practice_step3.
  ///
  /// In en, this message translates to:
  /// **'Step 3: Wait for recognition'**
  String get practice_step3;

  /// No description provided for @practice_step4.
  ///
  /// In en, this message translates to:
  /// **'Step 4: Mark as learned'**
  String get practice_step4;

  /// No description provided for @practice_step5.
  ///
  /// In en, this message translates to:
  /// **'Step 5: Continue practicing'**
  String get practice_step5;

  /// No description provided for @practice_hint.
  ///
  /// In en, this message translates to:
  /// **'Try to repeat the gesture as accurately as possible'**
  String get practice_hint;

  /// No description provided for @gesture_not_detected.
  ///
  /// In en, this message translates to:
  /// **'Gesture not detected'**
  String get gesture_not_detected;

  /// No description provided for @open_palm.
  ///
  /// In en, this message translates to:
  /// **'Open Palm'**
  String get open_palm;

  /// No description provided for @fist.
  ///
  /// In en, this message translates to:
  /// **'Fist'**
  String get fist;

  /// No description provided for @thumbs_up.
  ///
  /// In en, this message translates to:
  /// **'Thumbs Up'**
  String get thumbs_up;

  /// No description provided for @victory.
  ///
  /// In en, this message translates to:
  /// **'Victory'**
  String get victory;

  /// No description provided for @pointing.
  ///
  /// In en, this message translates to:
  /// **'Pointing'**
  String get pointing;

  /// No description provided for @rock.
  ///
  /// In en, this message translates to:
  /// **'Rock'**
  String get rock;

  /// No description provided for @unknown_gesture.
  ///
  /// In en, this message translates to:
  /// **'Unknown Gesture'**
  String get unknown_gesture;

  /// No description provided for @show_gesture.
  ///
  /// In en, this message translates to:
  /// **'Show Gesture'**
  String get show_gesture;

  /// No description provided for @step.
  ///
  /// In en, this message translates to:
  /// **'Step {step} of {total}'**
  String step(Object step, Object total);

  /// No description provided for @time_up.
  ///
  /// In en, this message translates to:
  /// **'Time\'s up!'**
  String get time_up;

  /// No description provided for @time_up_message.
  ///
  /// In en, this message translates to:
  /// **'You ran out of time. Try again!'**
  String get time_up_message;

  /// No description provided for @return_to_dictionary.
  ///
  /// In en, this message translates to:
  /// **'Return to Dictionary'**
  String get return_to_dictionary;

  /// No description provided for @image_unavailable.
  ///
  /// In en, this message translates to:
  /// **'Image unavailable'**
  String get image_unavailable;

  /// No description provided for @gesture_id.
  ///
  /// In en, this message translates to:
  /// **'Gesture ID'**
  String get gesture_id;

  /// No description provided for @gesture_data.
  ///
  /// In en, this message translates to:
  /// **'Gesture Data'**
  String get gesture_data;

  /// No description provided for @edit_gesture_info.
  ///
  /// In en, this message translates to:
  /// **'Edit Gesture Info'**
  String get edit_gesture_info;

  /// No description provided for @unsaved_changes.
  ///
  /// In en, this message translates to:
  /// **'Unsaved Changes'**
  String get unsaved_changes;

  /// No description provided for @unsaved_changes_confirm.
  ///
  /// In en, this message translates to:
  /// **'You have unsaved changes. Exit without saving?'**
  String get unsaved_changes_confirm;

  /// No description provided for @stay.
  ///
  /// In en, this message translates to:
  /// **'Stay'**
  String get stay;

  /// No description provided for @exit_without_saving.
  ///
  /// In en, this message translates to:
  /// **'Exit without saving'**
  String get exit_without_saving;

  /// No description provided for @id.
  ///
  /// In en, this message translates to:
  /// **'ID'**
  String get id;

  /// No description provided for @found.
  ///
  /// In en, this message translates to:
  /// **'Found'**
  String get found;

  /// No description provided for @total_gestures.
  ///
  /// In en, this message translates to:
  /// **'Total gestures'**
  String get total_gestures;

  /// No description provided for @no_gestures_to_display.
  ///
  /// In en, this message translates to:
  /// **'No gestures to display'**
  String get no_gestures_to_display;

  /// No description provided for @try_again_with_different_search.
  ///
  /// In en, this message translates to:
  /// **'Try again with a different search'**
  String get try_again_with_different_search;

  /// No description provided for @validation_username.
  ///
  /// In en, this message translates to:
  /// **'Enter a username'**
  String get validation_username;

  /// No description provided for @error_loading_gestures.
  ///
  /// In en, this message translates to:
  /// **'Error loading gestures'**
  String get error_loading_gestures;

  /// No description provided for @error_deleting_gesture.
  ///
  /// In en, this message translates to:
  /// **'Error deleting gesture'**
  String get error_deleting_gesture;

  /// No description provided for @gesture_marked_as_learned.
  ///
  /// In en, this message translates to:
  /// **'Gesture marked as learned!'**
  String get gesture_marked_as_learned;

  /// No description provided for @success_message.
  ///
  /// In en, this message translates to:
  /// **'You have successfully learned the gesture {gesture}!'**
  String success_message(Object gesture);

  /// No description provided for @registration.
  ///
  /// In en, this message translates to:
  /// **'Registration'**
  String get registration;

  /// No description provided for @admin.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get admin;

  /// No description provided for @user.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get user;

  /// No description provided for @reset_tests.
  ///
  /// In en, this message translates to:
  /// **'Reset tests'**
  String get reset_tests;

  /// No description provided for @deleted.
  ///
  /// In en, this message translates to:
  /// **'deleted'**
  String get deleted;

  /// No description provided for @gestures_not_found.
  ///
  /// In en, this message translates to:
  /// **'No gestures found'**
  String get gestures_not_found;

  /// No description provided for @correct_answer.
  ///
  /// In en, this message translates to:
  /// **'Correct answer'**
  String get correct_answer;

  /// No description provided for @no_tests.
  ///
  /// In en, this message translates to:
  /// **'No tests'**
  String get no_tests;

  /// No description provided for @alphabet_selection.
  ///
  /// In en, this message translates to:
  /// **'Alphabet selection'**
  String get alphabet_selection;

  /// No description provided for @no_letters.
  ///
  /// In en, this message translates to:
  /// **'No letters'**
  String get no_letters;

  /// No description provided for @dictionary.
  ///
  /// In en, this message translates to:
  /// **'Dictionary'**
  String get dictionary;

  /// No description provided for @saving_changes.
  ///
  /// In en, this message translates to:
  /// **'Saving changes...'**
  String get saving_changes;

  /// No description provided for @username.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get username;

  /// No description provided for @select_gesture.
  ///
  /// In en, this message translates to:
  /// **'Select gesture'**
  String get select_gesture;

  /// No description provided for @saving_letter.
  ///
  /// In en, this message translates to:
  /// **'Saving letter...'**
  String get saving_letter;

  /// No description provided for @please_enter_letter.
  ///
  /// In en, this message translates to:
  /// **'Please enter a letter'**
  String get please_enter_letter;

  /// No description provided for @enter_ukrainian_letter.
  ///
  /// In en, this message translates to:
  /// **'Enter a Ukrainian letter'**
  String get enter_ukrainian_letter;

  /// No description provided for @enter_english_letter.
  ///
  /// In en, this message translates to:
  /// **'Enter an English letter'**
  String get enter_english_letter;

  /// No description provided for @letter_deleted.
  ///
  /// In en, this message translates to:
  /// **'Letter deleted'**
  String get letter_deleted;

  /// No description provided for @error_deleting.
  ///
  /// In en, this message translates to:
  /// **'Error deleting'**
  String get error_deleting;

  /// No description provided for @error_deleting_letter.
  ///
  /// In en, this message translates to:
  /// **'Error deleting letter'**
  String get error_deleting_letter;

  /// No description provided for @alphabet_management.
  ///
  /// In en, this message translates to:
  /// **'Alphabet management'**
  String get alphabet_management;

  /// No description provided for @letter_data.
  ///
  /// In en, this message translates to:
  /// **'Letter data'**
  String get letter_data;

  /// No description provided for @enter_letter.
  ///
  /// In en, this message translates to:
  /// **'Enter letter'**
  String get enter_letter;

  /// No description provided for @unsaved_changes_message.
  ///
  /// In en, this message translates to:
  /// **'You have unsaved changes. Please save or discard them before leaving.'**
  String get unsaved_changes_message;

  /// No description provided for @editing_test.
  ///
  /// In en, this message translates to:
  /// **'Editing Test'**
  String get editing_test;

  /// No description provided for @test_id.
  ///
  /// In en, this message translates to:
  /// **'Test ID'**
  String get test_id;

  /// No description provided for @validation_test_question_length.
  ///
  /// In en, this message translates to:
  /// **'The test question is too short.'**
  String get validation_test_question_length;

  /// No description provided for @answer_option.
  ///
  /// In en, this message translates to:
  /// **'Answer option'**
  String get answer_option;

  /// No description provided for @notes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notes;

  /// No description provided for @notes_description.
  ///
  /// In en, this message translates to:
  /// **'Learn theory and useful materials'**
  String get notes_description;

  /// No description provided for @notes_management.
  ///
  /// In en, this message translates to:
  /// **'Notes management'**
  String get notes_management;

  /// No description provided for @notes_management_desc.
  ///
  /// In en, this message translates to:
  /// **'Add, edit and delete notes for users.'**
  String get notes_management_desc;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'uk'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'uk':
      return AppLocalizationsUk();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
