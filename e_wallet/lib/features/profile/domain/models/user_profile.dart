/// User domain entity representing the account holder.
class UserModel {
  const UserModel({
    required this.name,
    required this.email,
    required this.walletNumber,
  });

  final String name;
  final String email;
  final String walletNumber;
}
