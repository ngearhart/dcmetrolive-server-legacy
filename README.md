# DC Metro Live Server - Legacy 

The server used to power the MetroHero project, a (now defunct) app for WMATA Metrorail commuters and transit nerds in and around the DC area.

The original repository was forked into [DC Metro Live](dcmetro.live) and is located here. The end goal is to rewrite the backend using Python and Django, and host it using serverless functions on AWS (Zappa). However, for the time being, it runs in a container on ECS/Fargate.

## Setup

1. Copy `.env.sample` and replace the WMATA API key lines with your API keys. If you're already logged into developer.wmata.com, [click here](https://developer.wmata.com/developer), then copy the value for your "Primary key" into `PROD_WMATA_API_KEY` and your "Secondary key" into `DEV_WMATA_API_KEY`. If you have not yet been issued API keys from WMATA, [start here](https://developer.wmata.com/signup).

*That's it*

## Usage

1. `docker-compose up -d` - Then, use `docker-compose logs -f web` to watch the web container come up. That's it!!  
