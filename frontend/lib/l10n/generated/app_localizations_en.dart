// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Sport X Hub';

  @override
  String get themeToggleTooltip => 'Toggle dark mode';

  @override
  String get switchToEnglish => 'Switch to English';

  @override
  String get switchToArabic => 'Switch to Arabic';

  @override
  String get rolePlayer => 'Player';

  @override
  String get roleClub => 'Club';

  @override
  String get passwordLabel => 'Password';

  @override
  String get newPasswordLabel => 'New password';

  @override
  String get confirmNewPasswordLabel => 'Confirm new password';

  @override
  String get authWelcomeBack => 'Welcome back';

  @override
  String get authLogIn => 'Log in';

  @override
  String get authEmailLabel => 'Email';

  @override
  String get authEmailValidation => 'Enter a valid email';

  @override
  String get authIdentifierLabel => 'Email or phone number';

  @override
  String get authIdentifierValidation => 'Enter your email or phone number';

  @override
  String get authPasswordValidation => 'Enter your password';

  @override
  String get authForgotPassword => 'Forgot password?';

  @override
  String get authNoAccount => 'Don\'t have an account?';

  @override
  String get authRegister => 'Register';

  @override
  String get authNoAccountRegisterMobile => 'Don\'t have an account? Register';

  @override
  String get authCreateAccountTitle => 'Create account';

  @override
  String get authPasswordMinLength => 'At least 8 characters';

  @override
  String get authConfirmPassword => 'Confirm password';

  @override
  String get authPasswordMismatch => 'Passwords do not match';

  @override
  String get authAlreadyHaveAccount => 'Already have an account?';

  @override
  String get authForgotPasswordTitle => 'Reset your password';

  @override
  String get authResetPasswordTitle => 'Set a new password';

  @override
  String get authResetPasswordAppBarTitle => 'Reset password';

  @override
  String get authForgotSentMessage =>
      'If an account exists for that email, a reset link has been sent. In development, check the backend console log for the link.';

  @override
  String get authSendResetLink => 'Send reset link';

  @override
  String get authBackToLogin => 'Back to login';

  @override
  String get authResetDoneMessage =>
      'Your password has been reset. You can log in now.';

  @override
  String get authGoToLogin => 'Go to login';

  @override
  String get authResetPasswordButton => 'Reset password';

  @override
  String get authResetTokenMissing => 'This reset link is missing its token.';

  @override
  String get marketingNavHome => 'Home';

  @override
  String get marketingNavPlayers => 'Players';

  @override
  String get marketingNavClubs => 'Clubs';

  @override
  String get marketingNavAbout => 'About';

  @override
  String get marketingNavPricing => 'Pricing';

  @override
  String get marketingNavContact => 'Contact';

  @override
  String get homeHeroTitle => 'Where players get discovered.';

  @override
  String get homeHeroSubtitle =>
      'A Player builds a credible profile. A Club finds that player through search. A Club contacts them directly — no middleman, no noise.';

  @override
  String get homeGetStarted => 'Get started';

  @override
  String get homeBrowsePlayers => 'Browse players';

  @override
  String get homeFeatureBuildTitle => 'Build a profile';

  @override
  String get homeFeatureBuildBody =>
      'Personal info, sports stats, photos, video, achievements, and contact details — everything a Club needs to evaluate you.';

  @override
  String get homeFeatureFoundTitle => 'Get found';

  @override
  String get homeFeatureFoundBody =>
      'Clubs search by country, age, position, height, weight, preferred foot, and sport — filtered to exactly who they need.';

  @override
  String get homeFeatureContactedTitle => 'Get contacted';

  @override
  String get homeFeatureContactedBody =>
      'WhatsApp, email, or phone — a Club reaches out directly, the moment they find the right fit.';

  @override
  String get aboutTitle => 'About Sport X Hub';

  @override
  String get aboutBody1 =>
      'Sport X Hub is a professional sports talent marketplace connecting Players and Clubs. Our platform exists to validate one loop: a Player builds a credible profile, a Club finds that player through search, and a Club contacts them directly.';

  @override
  String get aboutBody2 =>
      'No noise, no middleman, no bloated feature set — just the fastest path from a real profile to a real conversation.';

  @override
  String get pricingTitle => 'Pricing';

  @override
  String get pricingSubtitle => 'Sport X Hub is free to join during launch.';

  @override
  String get pricingFree => 'Free';

  @override
  String get pricingPlayerFeature1 => 'Full player profile with photos & video';

  @override
  String get pricingPlayerFeature2 => 'Achievements and social links';

  @override
  String get pricingPlayerFeature3 => 'Public or private visibility';

  @override
  String get pricingPlayerFeature4 => 'Direct contact from interested Clubs';

  @override
  String get pricingClubFeature1 => 'Search players by 7 filters';

  @override
  String get pricingClubFeature2 => 'Save players to a shortlist';

  @override
  String get pricingClubFeature3 => 'Direct WhatsApp / email / phone contact';

  @override
  String get pricingClubFeature4 => 'Club profile page';

  @override
  String get contactTitle => 'Contact us';

  @override
  String get contactSubtitle =>
      'Questions, feedback, or partnership inquiries — send us a message.';

  @override
  String get contactNameLabel => 'Name';

  @override
  String get contactMessageLabel => 'Message';

  @override
  String get contactRequiredValidation => 'Required';

  @override
  String get contactSendMessage => 'Send message';

  @override
  String get contactSuccessMessage =>
      'Thanks — we received your message and will get back to you soon.';

  @override
  String get playersNoResults => 'No players match these filters.';

  @override
  String get filtersTooltip => 'Filters';

  @override
  String get clubsListingTitle => 'Clubs on Sport X Hub';

  @override
  String get clubsNoResults => 'No clubs to show yet.';

  @override
  String get unnamedClub => 'Unnamed club';

  @override
  String get dashboardRoleAdmin => 'Admin';

  @override
  String dashboardTitleWithRole(String role) {
    return '$role Dashboard';
  }

  @override
  String dashboardComingSoon(String role) {
    return '$role Dashboard — coming in a later phase';
  }

  @override
  String get dashboardSidebarTitle => 'Dashboard';

  @override
  String get dashboardMyProfile => 'My Profile';

  @override
  String get dashboardEditProfile => 'Edit Profile';

  @override
  String get dashboardAdminUsers => 'Admin — Users';

  @override
  String get dashboardAdminPlayersClubs => 'Admin — Players & Clubs';

  @override
  String get dashboardMyClub => 'My Club';

  @override
  String get dashboardEditClubProfile => 'Edit Club Profile';

  @override
  String get dashboardSearchPlayers => 'Search Players';

  @override
  String get dashboardSavedPlayers => 'Saved Players';

  @override
  String get dashboardAccountSettings => 'Account Settings';

  @override
  String get dashboardAdminMobileHint =>
      'Admin tooling is available on Desktop.';

  @override
  String get dashboardNavSettings => 'Settings';

  @override
  String get logoutTooltip => 'Log out';

  @override
  String get saveLabel => 'Save';

  @override
  String get cancelLabel => 'Cancel';

  @override
  String get deleteLabel => 'Delete';

  @override
  String get removeLabel => 'Remove';

  @override
  String get anyOption => 'Any';

  @override
  String get previewLabel => 'Preview';

  @override
  String get sectionAboutTitle => 'About';

  @override
  String get backLabel => 'Back';

  @override
  String get backToPlayersLabel => 'Back to Players';

  @override
  String get shareProfileLabel => 'Share Profile';

  @override
  String get shareProfileLinkCopied => 'Profile link copied to clipboard';

  @override
  String get ageLabel => 'Age';

  @override
  String get personalInfoTitle => 'Personal Information';

  @override
  String get firstNameLabel => 'First name';

  @override
  String get lastNameLabel => 'Last name';

  @override
  String get dateOfBirthLabel => 'Date of birth';

  @override
  String get selectDateLabel => 'Select date';

  @override
  String get nationalityLabel => 'Nationality';

  @override
  String get countryLabel => 'Country';

  @override
  String get cityLabel => 'City';

  @override
  String get sportsInfoTitle => 'Sports Information';

  @override
  String get sportLabel => 'Sport';

  @override
  String get positionLabel => 'Position';

  @override
  String get footballPositionSectionTitle => 'Football Position';

  @override
  String get footballPositionPickerSubtitle =>
      'Choose your primary position on the pitch';

  @override
  String get footballPositionEditHint =>
      'Tap a position to set it as primary (tap again to clear it). Long-press to add or remove it as an alternate position.';

  @override
  String get footballPositionViewHint =>
      'Highlighted markers show this player\'s positions.';

  @override
  String get footballPositionPrimaryLabel => 'Current position';

  @override
  String get footballPositionSecondaryLabel => 'Alternate position';

  @override
  String get footballPositionOtherLabel => 'Other positions';

  @override
  String get footballPositionNoneSelected => 'No position set yet';

  @override
  String get footballPositionGk => 'Goalkeeper';

  @override
  String get footballPositionLb => 'Left Back';

  @override
  String get footballPositionCb => 'Centre Back';

  @override
  String get footballPositionRb => 'Right Back';

  @override
  String get footballPositionCdm => 'Defensive Midfield';

  @override
  String get footballPositionCm => 'Central Midfield';

  @override
  String get footballPositionCam => 'Attacking Midfield';

  @override
  String get footballPositionLw => 'Left Winger';

  @override
  String get footballPositionRw => 'Right Winger';

  @override
  String get footballPositionSt => 'Striker';

  @override
  String get footballPositionCf => 'Centre Forward';

  @override
  String get footballPositionGkDesc =>
      'Protects the goal and organizes the defense';

  @override
  String get footballPositionLbDesc =>
      'Supports defense and attack down the left';

  @override
  String get footballPositionCbDesc => 'Stops attacks and protects the goal';

  @override
  String get footballPositionRbDesc =>
      'Supports defense and attack down the right';

  @override
  String get footballPositionCdmDesc =>
      'Screens the defense and wins the ball back';

  @override
  String get footballPositionCmDesc => 'Links defense with attack';

  @override
  String get footballPositionCamDesc => 'Creates chances and unlocks defenses';

  @override
  String get footballPositionLwDesc => 'Pace and skill down the left flank';

  @override
  String get footballPositionRwDesc => 'Pace and skill down the right flank';

  @override
  String get footballPositionStDesc => 'Leads the line as the main goal threat';

  @override
  String get footballPositionCfDesc => 'Team\'s central striker and top scorer';

  @override
  String get basketballPositionSectionTitle => 'Basketball Position';

  @override
  String get basketballPositionPickerSubtitle =>
      'Choose your primary position on the court';

  @override
  String get basketballPositionEditHint =>
      'Tap a position to set it as primary (tap again to clear it). Long-press to add or remove it as an alternate position.';

  @override
  String get basketballPositionViewHint =>
      'Highlighted markers show this player\'s positions.';

  @override
  String get basketballPositionPrimaryLabel => 'Current position';

  @override
  String get basketballPositionSecondaryLabel => 'Alternate position';

  @override
  String get basketballPositionOtherLabel => 'Other positions';

  @override
  String get basketballPositionNoneSelected => 'No position set yet';

  @override
  String get basketballPositionPg => 'Point Guard';

  @override
  String get basketballPositionSg => 'Shooting Guard';

  @override
  String get basketballPositionSf => 'Small Forward';

  @override
  String get basketballPositionPf => 'Power Forward';

  @override
  String get basketballPositionC => 'Center';

  @override
  String get basketballPositionPgDesc => 'Leads the offense and runs the play';

  @override
  String get basketballPositionSgDesc => 'Specializes in perimeter shooting';

  @override
  String get basketballPositionSfDesc =>
      'Versatile scorer on offense and defense';

  @override
  String get basketballPositionPfDesc =>
      'Strength inside on defense and rebounding';

  @override
  String get basketballPositionCDesc =>
      'Protects the rim and controls rebounds';

  @override
  String get preferredFootLabel => 'Preferred foot';

  @override
  String get heightLabel => 'Height (cm)';

  @override
  String get weightLabel => 'Weight (kg)';

  @override
  String get heightStatLabel => 'Height';

  @override
  String get weightStatLabel => 'Weight';

  @override
  String get currentStatusLabel => 'Current status';

  @override
  String get currentClubLabel => 'Current club';

  @override
  String get statusStatLabel => 'Status';

  @override
  String get preferredFootLeft => 'Left';

  @override
  String get preferredFootRight => 'Right';

  @override
  String get preferredFootBoth => 'Both';

  @override
  String get aboutContactTitle => 'About & Contact';

  @override
  String get bioLabel => 'Bio';

  @override
  String get phoneLabel => 'Phone number';

  @override
  String get contactEmailLabel => 'Contact email';

  @override
  String get whatsappLabel => 'WhatsApp number';

  @override
  String get photosVideosTitle => 'Photos & Videos';

  @override
  String get addPhotoLabel => 'Add photo';

  @override
  String get addVideoLabel => 'Add video';

  @override
  String get achievementsTitle => 'Achievements';

  @override
  String get noAchievementsYet => 'No achievements added yet.';

  @override
  String get addAchievementTooltip => 'Add achievement';

  @override
  String get editAchievementTitle => 'Edit achievement';

  @override
  String get addAchievementTitle => 'Add achievement';

  @override
  String get achievementTitleLabel => 'Title';

  @override
  String get yearLabel => 'Year';

  @override
  String get descriptionLabel => 'Description';

  @override
  String get achievementValidation => 'Enter a title and a valid year.';

  @override
  String get socialLinksTitle => 'Social Links';

  @override
  String get noSocialLinksYet => 'No social links added yet.';

  @override
  String get addSocialLinkTooltip => 'Add social link';

  @override
  String get editSocialLinkTitle => 'Edit social link';

  @override
  String get addSocialLinkTitle => 'Add social link';

  @override
  String get platformLabel => 'Platform';

  @override
  String get platformHint => 'Instagram, YouTube, X…';

  @override
  String get urlLabel => 'URL';

  @override
  String get socialLinkValidation => 'Enter a platform and a URL.';

  @override
  String get visibilityTitle => 'Profile Visibility';

  @override
  String get visibilityPublicDesc =>
      'Your profile is visible to Clubs in search results.';

  @override
  String get visibilityPrivateDesc =>
      'Your profile is hidden from search and public view.';

  @override
  String get publicProfileLabel => 'Public profile';

  @override
  String get unnamedPlayer => 'Unnamed player';

  @override
  String get galleryTitle => 'Gallery';

  @override
  String get contactSectionTitle => 'Contact';

  @override
  String contactPhoneValue(String value) {
    return 'Phone: $value';
  }

  @override
  String contactEmailValue(String value) {
    return 'Email: $value';
  }

  @override
  String contactWhatsappValue(String value) {
    return 'WhatsApp: $value';
  }

  @override
  String get savePlayerTooltip => 'Save player';

  @override
  String get removeSavedTooltip => 'Remove from saved';

  @override
  String get contactWhatsappButton => 'WhatsApp';

  @override
  String get contactEmailButton => 'Email';

  @override
  String get contactCallButton => 'Call';

  @override
  String get myProfileTitle => 'My Profile';

  @override
  String get clubInfoTitle => 'Club Information';

  @override
  String get clubNameLabel => 'Club name';

  @override
  String get foundedYearLabel => 'Founded year';

  @override
  String get levelLabel => 'Level';

  @override
  String get levelHint => 'Professional, Amateur, Academy…';

  @override
  String get foundedStatLabel => 'Founded';

  @override
  String get clubLogoTitle => 'Club Logo';

  @override
  String get uploadingLabel => 'Uploading…';

  @override
  String get uploadLogoLabel => 'Upload logo';

  @override
  String get minAgeLabel => 'Min age';

  @override
  String get maxAgeLabel => 'Max age';

  @override
  String get minHeightLabel => 'Min height (cm)';

  @override
  String get maxHeightLabel => 'Max height (cm)';

  @override
  String get applyFiltersLabel => 'Apply filters';

  @override
  String get noSavedPlayers => 'You have not saved any players yet.';

  @override
  String signedInAs(String email) {
    return 'Signed in as $email';
  }

  @override
  String get emailSectionTitle => 'Email';

  @override
  String get newEmailLabel => 'New email';

  @override
  String get saveEmailLabel => 'Save email';

  @override
  String get emailUpdatedMessage => 'Email updated.';

  @override
  String get passwordUpdatedMessage => 'Password updated.';

  @override
  String get currentPasswordLabel => 'Current password';

  @override
  String get changePasswordLabel => 'Change password';

  @override
  String get playersClubsNavLabel => 'Players & Clubs';

  @override
  String get usersTabLabel => 'Users';

  @override
  String get deleteUserTitle => 'Delete user?';

  @override
  String deleteUserContent(String email) {
    return 'This permanently deletes $email. This cannot be undone.';
  }

  @override
  String get activateLabel => 'Activate';

  @override
  String get suspendLabel => 'Suspend';

  @override
  String get deleteUserTooltip => 'Delete user';

  @override
  String get noUsersFound => 'No users found.';

  @override
  String get emailColumnLabel => 'Email';

  @override
  String get roleColumnLabel => 'Role';

  @override
  String get statusColumnLabel => 'Status';

  @override
  String get actionsColumnLabel => 'Actions';

  @override
  String get loadMoreLabel => 'Load more';

  @override
  String get playersTabLabel => 'Players';

  @override
  String get clubsTabLabel => 'Clubs';

  @override
  String get removePlayerProfileTitle => 'Remove player profile?';

  @override
  String removePlayerProfileContent(String name) {
    return 'This permanently deletes the profile for $name, including their photos and videos. This cannot be undone.';
  }

  @override
  String get thisPlayerFallback => 'this player';

  @override
  String get removeProfileTooltip => 'Remove profile';

  @override
  String get noPlayerProfilesFound => 'No player profiles found.';

  @override
  String get nameColumnLabel => 'Name';

  @override
  String get sportColumnLabel => 'Sport';

  @override
  String get positionColumnLabel => 'Position';

  @override
  String get visibilityColumnLabel => 'Visibility';

  @override
  String get unnamedShort => 'Unnamed';

  @override
  String get removeClubProfileTitle => 'Remove club profile?';

  @override
  String removeClubProfileContent(String name) {
    return 'This permanently deletes the profile for $name, including its logo. This cannot be undone.';
  }

  @override
  String get thisClubFallback => 'this club';

  @override
  String get noClubProfilesFound => 'No club profiles found.';

  @override
  String get playerProfileNotAvailable =>
      'This player profile is not available.';

  @override
  String get clubProfileNotAvailable => 'This club profile is not available.';

  @override
  String dashboardWelcomeMessage(String name) {
    return 'Welcome back, $name';
  }

  @override
  String get dashboardWelcomeMessageNoName => 'Welcome back';

  @override
  String get dashboardProfileCompletionTitle => 'Profile Completion';

  @override
  String dashboardProfileCompletePercent(int percent) {
    return '$percent% complete';
  }

  @override
  String get dashboardProfileCompleteMessage =>
      'Your profile is complete — nice work.';

  @override
  String get dashboardMissingFieldsHint =>
      'Complete these to get discovered by more clubs:';

  @override
  String get dashboardStatSavedByClubs => 'Saved by clubs';

  @override
  String get dashboardStatMedia => 'Media items';

  @override
  String get dashboardStatAchievements => 'Achievements';

  @override
  String get dashboardQuickActionsTitle => 'Quick Actions';

  @override
  String get dashboardMissingProfilePhoto => 'Profile photo';

  @override
  String get dashboardMissingContact => 'Contact details';

  @override
  String get noSportsInfoYet => 'No sports information added yet.';

  @override
  String profileCompletionLabel(int percent) {
    return 'Profile completion: $percent%';
  }

  @override
  String fieldsRemainingHint(int count) {
    return '$count fields left to complete your profile.';
  }

  @override
  String get profilePhotoSectionTitle => 'Profile Photo';

  @override
  String get changePhotoLabel => 'Change photo';

  @override
  String get uploadPhotoLabel => 'Upload photo';

  @override
  String get saveAndViewProfileLabel => 'Save & view profile';

  @override
  String get profileSavedMessage => 'Profile saved.';

  @override
  String get communityNavLabel => 'Community';

  @override
  String get communityEmptyState => 'No videos yet for this sport/category.';

  @override
  String get allCategoryLabel => 'All';

  @override
  String get skillsSectionTitle => 'Skills';

  @override
  String get traitsTitle => 'Traits';

  @override
  String get traitsCaption =>
      'Grows as you upload more videos in each skill — liked videos count extra.';

  @override
  String get videosEmptyState => 'No videos yet in this category.';

  @override
  String get videoDeleteTitle => 'Delete video?';

  @override
  String get videoDeleteContent => 'This cannot be undone.';

  @override
  String get videoMakePrivate => 'Make private';

  @override
  String get videoMakePublic => 'Make public';

  @override
  String get videoEditTitleLabel => 'Edit title';

  @override
  String get videoUploadTitle => 'Add video';

  @override
  String get videoChooseFileLabel => 'Choose video file';

  @override
  String get videoTitleLabel => 'Video title (optional)';

  @override
  String get videoCategoryLabel => 'Category';

  @override
  String get videoCategoriesLoadError => 'Could not load categories.';

  @override
  String get videoVisibilityPublic => 'Public';

  @override
  String get videoVisibilityPrivate => 'Private';

  @override
  String get videoUploadButtonLabel => 'Upload';

  @override
  String get videoUploadMissingFieldsError =>
      'Choose a video and a category before uploading.';

  @override
  String videoUploadTooLargeError(int limit) {
    return 'This video is larger than the ${limit}MB limit. Choose a smaller file.';
  }

  @override
  String get videoUploadTimeoutError =>
      'The upload took too long and timed out. Check your connection and try again.';

  @override
  String get videoPlaybackErrorMessage => 'This video could not be played.';

  @override
  String get videoPlaybackRetryLabel => 'Retry';

  @override
  String get videoCommentsTitle => 'Comments';

  @override
  String get videoCommentsEmptyState =>
      'No comments yet. Be the first to say something.';

  @override
  String get videoCommentHint => 'Add a comment…';

  @override
  String get videoCommentsLoadMore => 'Load more';

  @override
  String get videoCommentDeleteTitle => 'Delete comment?';

  @override
  String get videoCommentDeleteContent => 'This cannot be undone.';

  @override
  String pageOfPagesLabel(int page, int lastPage) {
    return 'Page $page of $lastPage';
  }

  @override
  String communityActivityLabel(int total, String sport) {
    return '$total videos in $sport';
  }

  @override
  String get genericErrorMessage => 'Something went wrong. Please try again.';

  @override
  String get retryButtonLabel => 'Retry';
}
