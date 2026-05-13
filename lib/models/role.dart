enum Role {
  driver('DRIVER');

  final String role;

  const Role(this.role);

  @override
  String toString() {
    return role;
  }
}
