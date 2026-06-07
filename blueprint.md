# HotShare App Blueprint

## Overview

HotShare is a Flutter application that allows users to easily share files between devices on the same local network. It provides a simple and intuitive interface for selecting files, starting a local server, and sharing a QR code or URL for others to download the files.

## Features

*   **File Selection:** Users can pick multiple files from their device to share.
*   **Local Server:** A local HTTP server is created to host the selected files.
*   **QR Code Sharing:** A QR code is generated for the server's URL, allowing for easy sharing with mobile devices.
*   **Direct URL Access:** Users can also access the files by entering the provided URL in their browser.
*   **Dark/Light Mode:** The application supports both dark and light themes and can also follow the system theme.
*   **Cross-Platform:** Built with Flutter, HotShare is designed to run on multiple platforms, including web and desktop.

## Design and Styling

*   **Theme:** The application uses Material Design 3 with a custom color scheme seeded from `Colors.deepPurple`.
*   **Typography:** The app uses Google Fonts for a clean and modern look:
    *   `Oswald` for display and title text.
    *   `Roboto` for buttons and other UI elements.
    *   `Open Sans` for body text.
*   **Layout:** The layout is a single-page interface that adapts to the application's state (i.e., whether the server is running or not).
    *   When the server is off, the app displays the list of selected files and provides controls for adding or clearing files.
    *   When the server is on, the app displays the QR code and the server URL.

