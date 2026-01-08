[Home](../index.md)

# Simple Home Network VPN Gateway

## Motivation

Over a year ago, I build a Voron 2.4 R2 printer. I wanted an easy way to access the web interface for the printer remotely from my phone. The webapp, Mainsail, has no security whatsoever, so simply port forwarding the site and exposing it to the open internet was not an option. My first thought was that it should be trivial to setup some VPN server and tunnel encrypted traffic from authenticated devices into to my local network, as surely this is a common situation. I had an old laptop (that happens to have an ethernet port) sitting around with Fedora installed on it, so I figured I would give it a go. I knew very little about Linux networking at the time, so after about a week of struggling with OpenVPN and Wiregaurd, I gave up. I grabbed a spare RasperyPi, flashed it with [PiVPN](https://www.pivpn.io/) and called it a day.

But that sucks. I don't want to have to waste an entire RaspberryPi and LAN port on my router just for a VPN. Worse than that, my network security now relies on a black box that I don't understand.

## Goal

This blog post is going to explain how to setup a home network Wiregaurd VPN gateway, and hopefully teach some cool Linux networking concepts along the way. This setup is meant to be as simple as possible, and just requires that you have a Linux computer with a wired ethernet connection to your router: the specification that it is wired is important.