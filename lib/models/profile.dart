class Profile {
  final String id, name, surname, username, profilePictureUrl;
  final int? age;

  Profile({
    required this.id,
    required this.name,
    required this.surname,
    required this.username,
    required this.age,
    required this.profilePictureUrl,
  });

  factory Profile.fromMap(Map<String, dynamic> map) => Profile(
    id: map['id'],
    name: map['name'],
    surname: map['surname'],
    username: map['username'],
    age: map['age'] as int?,
    profilePictureUrl: map['profile_picture_url'],
  );
}
