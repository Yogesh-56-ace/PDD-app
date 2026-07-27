class TestData:
    VALID_USERS = [
        {"email": "user1@posturefixpro.com", "password": "Password123!", "role": "Standard User"},
        {"email": "admin@posturefixpro.com", "password": "AdminSecure456!", "role": "Administrator"}
    ]

    INVALID_EMAILS = [
        "plainaddress",
        "#@%^%#$@#$@#.com",
        "@example.com",
        "Joe Smith <email@example.com>",
        "email.example.com",
        "email@example@example.com",
        "email@example.com (Joe Smith)"
    ]

    VIEWPORTS = [
        {"name": "Mobile Portrait", "width": 375, "height": 812},
        {"name": "Mobile Landscape", "width": 812, "height": 375},
        {"name": "Tablet Portrait", "width": 768, "height": 1024},
        {"name": "Tablet Landscape", "width": 1024, "height": 768},
        {"name": "Desktop Full HD", "width": 1920, "height": 1080}
    ]

    MODULE_CATEGORIES = [
        ("Authentication", 40),
        ("Authorization", 40),
        ("Navigation", 30),
        ("UI Validation", 50),
        ("Forms", 50),
        ("CRUD Operations", 50),
        ("Input Validation", 40),
        ("Error Handling", 20),
        ("Session Management", 20),
        ("File Upload", 20),
        ("Accessibility", 20),
        ("Responsive Design", 20),
        ("Performance Smoke Tests", 20),
        ("Regression", 50)
    ]
