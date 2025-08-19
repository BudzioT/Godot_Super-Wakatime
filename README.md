<a id="readme-top"></a>

<!-- SHIELDS -->
[![Contributors][contributors-shield]][contributors-url]
[![Forks][forks-shield]][forks-url]
[![Stargazers][stars-shield]][stars-url]
[![Issues][issues-shield]][issues-url]
[![MIT License][license-shield]][license-url]

<!-- HEADER -->
<br />
<div align="center">
    <a href="https://github.com/BudzioT/Godot_Super-Wakatime">
        <img src="https://cloud-bo1ln2br1-hack-club-bot.vercel.app/0godotwaka22.png"  alt="Godot Wakatime"/>
    </a>
    <h3 align="center"> Godot Super Wakatime </h3>
    <p align="center">
        Tool to measure time spent in loved by many people game engine - Godot
        <br />
        Officially approved to use in events created by Hack Club
        <br />
        <br />
        <a href="https://godotengine.org/asset-library/asset/3484">Get from Asset Lib</a>
        ·
        <a href="https://youtu.be/rqAc-YdVXyM">View Demo</a>
        ·
        <a href="https://github.com/BudzioT/Godot_Super-Wakatime/issues/new">Report Bug / Request Feature</a>
    </p>
</div>

<!-- CONTENTS -->
<details>
    <summary>Table of Contents</summary>
    <ol>
        <li>
            <a href="#about">About The Project</a>
            <ul>
                <li><a href="#built-with">Built Using</a></li>
            </ul>
        </li>
        <li>
            <a href="#getting-started">Getting Started</a>
            <ul>
                <li><a href="#installation">Installation</a></li>
            </ul>
        </li>
        <li><a href="#usage">Usage</a></li>
        <li><a href="#license">License</a></li>
    </ol>
</details>


<!-- ABOUT -->
## About The Project
<br />

[![Product Screenshot][product-screenshot]](https://waka.hackclub.com)

This tool can successfully measure time spent building your games or apps in Godot.
<br />
Here's why:
* It differentiates between switching a scene and script
* It counts key presses as coding and mouse clicks as building scene
* Changing scene structure results in a heartbeat sent
* It correctly detects OS, machine name, language, editor, files
* It can detect your cursor line and position
* Time is split between: Building, Coding, Testing
* In the future it will also detect testing your projects

It works on both Linux and Windows, it wasn't tested on macOS yet
<br />
You can also see your time spent in the editor itself:
[![Time in editor][time-screenshot]]

<p align="right">(<a href="#readme-top">top</a>)</p>


### Built Using
I used the Ouch! CLI tool for decompression of files <br />
This project was built using one simple, yet powerful language.<br />
It required a lot of workarounds, but it was a pleasure to use it
* [![GDScript][Godot]][Godot-url]
* [![Ouch!][Ouch-shield]][Ouch-url]

<p align="right">(<a href="#readme-top">top</a>)</p>

<!-- GETTING STARTED -->
## Getting Started
How to install and use this software? It's easy!

### Installation
You can either download it from the [Godot Asset Library](https://godotengine.org/asset-library/asset/3484).
<br />Or you can manually install it, here's how to do it!
1. Clone the repository
    ```sh
    git clone https://github.com/BudzioT/Godot_Super-Wakatime.git
    ```
2. Go into your project
3. Insert the entire `./addons` folder into your project `res://` directory

<p align="right">(<a href="#readme-top">top</a>)</p>

<!-- USAGE -->
## Usage
Don't know how to use this plugin? Here are the steps:
1. Turn on the plugin in your plugins. In your `Project -> Project Settings -> Plugins -> `Click the `Enable` checkbox near this plugin
2. If prompted for API key, provide it from Wakatime website
3. if there is an issue with it, please manually create `~/.wakatime.cfg` file with these contents or use the setup script available at the [Hackatime configuration page](https://hackatime.hackclub.com/my/wakatime_setup) :
    ```sh
    [settings]
    api_key=xxxx
    ```
    Where xxxx is your api key
<br /><br />
If you are coming from Hack Club use this:
    ```sh
    [settings]
    api_url = https://hackatime.hackclub.com/api/hackatime/v1
    api_key=xxxx
    ```
4. Wakatime CLI should have been installed automatically along with Ouch! Decompression library
5. Work on your project! You should see your results on either Wakatime or Hackatime!
6. You can also see your time at the bottom panel

<p align="right">(<a href="#readme-top">top</a>)</p>

<!-- LICENSE -->
## License

Distributed under the MIT License. See `LICENSE` for more information.

<p align="right">(<a href="#readme-top">back to top</a>)</p>


<!-- URLS -->
[contributors-shield]: https://img.shields.io/github/contributors/budziot/Godot_Super-Wakatime?style=for-the-badge
[contributors-url]: https://github.com/BudzioT/Godot_Super-Wakatime/graphs/contributors
[forks-shield]: https://img.shields.io/github/forks/budziot/Godot_Super-Wakatime?style=for-the-badge
[forks-url]: https://github.com/BudzioT/Godot_Super-Wakatime/forks
[stars-shield]: https://img.shields.io/github/stars/budziot/Godot_Super-Wakatime?style=for-the-badge
[stars-url]: https://github.com/BudzioT/Godot_Super-Wakatime/stargazers
[issues-shield]: https://img.shields.io/github/issues/budziot/Godot_Super-Wakatime?style=for-the-badge
[issues-url]: https://github.com/BudzioT/Godot_Super-Wakatime/issues
[license-shield]: https://img.shields.io/github/license/budziot/Godot_Super-Wakatime?style=for-the-badge
[license-url]: https://github.com/BudzioT/Godot_Super-Wakatime/blob/master/addons/godot_super-wakatime/LICENSE
[product-screenshot]: https://cloud-j4wibbzz7-hack-club-bot.vercel.app/0image.png
[product-logo]: https://cloud-j4wibbzz7-hack-club-bot.vercel.app/2godotwaka2.png
[Godot]: https://img.shields.io/badge/Godot%20Engine-478CBF?logo=godotengine&logoColor=fff&style=flat
[Godot-url]: https://godotengine.org/
[Ouch-shield]: https://img.shields.io/badge/Ouch!-tool-blue?label=Ouch!
[Ouch-url]: https://github.com/ouch-org/ouch
[time-screenshot]: https://cloud-l88kldf50-hack-club-bot.vercel.app/0image.png
