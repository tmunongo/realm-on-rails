---
title: Deploying a NextJS app with Nginx using Docker
author: Tawanda Munongo
bio: I spend most of my days learning about and building software systems. When I inevitably learn something new, I come here and write about it. Once in a while, I might throw in some fiction and philosophy.
linkedin: https://linkedin.com/in/tawanda-munongo
github: https://github.com/tmunongo
cover: http://res.cloudinary.com/ta1da-cloud/image/upload/v1668158175/realm/covers/Deploying%20a%20NextJS%20app%20with%20Nginx%20using%20Docker.png
tags: ["Tutorial", "NextJS", "Nginx", "Docker"]
description: In this tutorial I show how to use Docker to build and deploy a simple Next.js app and serve the static files with Nginx.
publishDate: 2022-11-11
---

# Requirements

- Linux
- Docker
- Node (optional, to test the application locally)
- VS Code (or a text editor of your choice)
  _This tutorial includes affiliate links._

# Introduction

In this tutorial, I am going to be showing how to build a simple Next.js application, connect to and query a MongoDB database using Prisma, and serve the static files using Nginx. One might wonder why you would use Nginx as your web server instead of simply running `npm start` in your production environment, but there are a few reasons.

## Why use a "real" web server

- Performance benefits: building our app outputs minified and optimized code which will reduce the size of the application, reducing the load on the server.
- Security: Nginx is "battle-tested" and it has HTTPS capabilities built-in with better performance.
- Better tooling: Nginx provides logging, the ability to restrict, allow, or redirect server calls, load balancing, caching, and so much more.

# Building our Next.js Application

Despite the recent release of Next.js 13 with a whole bunch of awesome, new features, we will be using version 12 for this tutorial. We can use `create-next-app` to set up everything automatically using the command:
`npx create-next-app@12 --typescript`
![Creating a NextJS app](https://res.cloudinary.com/ta1da-cloud/image/upload/v1668155906/realm/tutorials/next-docker-nginx/create_next_app_vvsriv.png)
This sets up our project by installing import development packages including adding typescript support. We can test that our application is running with `npm run dev` and access the web app at `http://localhost:3000`. You should see this:
![Starter Next App](https://res.cloudinary.com/ta1da-cloud/image/upload/v1668155911/realm/tutorials/next-docker-nginx/starter_next_app_fkcux2.png)
Before we continue, we can clear up all the markup for the original _index.tsx_ page.
![Initial Markup Cleared](https://res.cloudinary.com/ta1da-cloud/image/upload/v1668155909/realm/tutorials/next-docker-nginx/next_app_cleared_lrzjrj.png)

> This rest of the section on styling the web app is not an essential part of the tutorial. Feel free to skip ahead to the section on setting up Prisma.
> First, use npm to install the required dependencies, then run the _init_ command to generate the required config files.
> `npm install -D tailwindcss postcss autoprefixer` && `npm tailwindcss init -p`
> Modify the _tailwind.config.js_ file to include the paths to all our templates by including these lines.

```javascript
content: [ './app/**/*.{js,ts,jsx,tsx}',
'./pages/**/*.{js,ts,jsx,tsx}',
'./components/**/*.{js,ts,jsx,tsx}', ],
```

The next step is to add the Tailwind directive to the default CSS file, which is the _globals.css_ file located in the **styles** folder. You may clear the contents of the folder. Once this is done, we can add some simple CSS to our _index.tsx_ template to test the configuration.
![Styled Index Page](https://res.cloudinary.com/ta1da-cloud/image/upload/v1668155911/realm/tutorials/next-docker-nginx/Styled_Index_Page_r7sriv.png)
We can also create a second page and implement a layout to demonstrate routing capabilities in the app. This is easy thanks to file-system routing in Next.js which means that we only need to create a file in the **pages** folder.
The code for the Nav Bar and Layout components is shown below.
![Nav Bar Component](https://res.cloudinary.com/ta1da-cloud/image/upload/v1668155908/realm/tutorials/next-docker-nginx/NavBar_Component_j8eonv.png)
![Layout Component](https://res.cloudinary.com/ta1da-cloud/image/upload/v1668155907/realm/tutorials/next-docker-nginx/Layout_Component_n73nor.png)
This is what our app looks like, now.
![Styled app](https://res.cloudinary.com/ta1da-cloud/image/upload/v1668155908/realm/tutorials/next-docker-nginx/Homepage_with_Nav_pz1coe.png)

# Adding Prisma ORM

Prisma is an _"open source next-generation ORM"_. It allows us to interface easily with our database without having to write, for example, SQL if working with a relational DB. Instead, we just need to write our schema and the Prisma Client does the rest. It can be used in any Node.js or TypeScript backend application. In this case, we will we using it with MongoDB.
Start by adding Prisma CLI as a dev dependency to the project.
`npm install -D prisma`
![Installing Prisma CLI](https://res.cloudinary.com/ta1da-cloud/image/upload/v1668155905/realm/tutorials/next-docker-nginx/Install_Prisma_jbc9lf.png)
Next, invoke Prisma to create a template schema file with the command `npx prisma init`.
According to Prisma docs, this command creates a **prisma** directory with a _prisma.schema_ file and a new _.env_ file to store the DB connection URL (and any other secrets you might have).
![Prisma Schema File](https://res.cloudinary.com/ta1da-cloud/image/upload/v1668155909/realm/tutorials/next-docker-nginx/Prisma_Schema_File_wlwxia.png)
Set the datasource provider to 'mongodb' and add your connection URL to the _.env_ file. The URL takes the format `mongodb://{username}:{password}@{hostname}/{db_name}?authSource=admin&retryWrites=true&w=majority`.
We will be using an instance of MongoDB running inside a Docker container. If you don't have Docker installed, you can visit [store.docker.com](store.docker.com) and follow the installation process for your development environment. Alternatively, you can use a Mongo Atlas-hosted database, but Docker will still be a requirement later on. If you're not running Linux, you can create a free Linux VM on Oracle Cloud or [Digital Ocean](https://m.do.co/c/d9f737e3f31c). Digital Ocean offers $200 worth of free credits valid for 90 days to new customers.
Now, create a simple schema for the database.
![Database Post Schema](https://res.cloudinary.com/ta1da-cloud/image/upload/v1668155908/realm/tutorials/next-docker-nginx/Post_Schema_fhlqtk.png)
The next step is to install the Prisma client and generate the queries, but we must first set up MongoDB. To use MongoDB with Prisma, we must create a replica set, otherwise we will encounter errors in generating our schema.

# Setting up MongoDB inside a Docker Container

Run the command `docker --version` if you have just installed Docker and need to verify that Docker Engine is running. Prisma [provides a Dockerfile](https://github.com/prisma/prisma/blob/main/docker/mongodb_replica/Dockerfile) to build the Docker image as per the required specifications. For simplicity, you can create a _Dockerfile_ in a new, separate folder and paste the following into it.

```dockerfile
FROM mongo:4 # we take over the default & start mongo in replica set mode in a background task
ENTRYPOINT mongod --port $MONGO_REPLICA_PORT --replSet rs0 --bind_ip 0.0.0.0 & MONGOD_PID=$!;
# we prepare the replica set with a single node and prepare the root user config
INIT_REPL_CMD="rs.initiate({ _id: 'rs0', members: [{ _id: 0, host: '$MONGO_REPLICA_HOST:$MONGO_REPLICA_PORT' }] })";
INIT_USER_CMD="db.createUser({ user: '$MONGO_INITDB_ROOT_USERNAME', pwd: '$MONGO_INITDB_ROOT_PASSWORD', roles: [ 'root' ] })"; \
# we wait for the replica set to be ready and then submit the commands just above until (mongo admin --port $MONGO_REPLICA_PORT --eval "$INIT_REPL_CMD && $INIT_USER_CMD");
do sleep 1; done; \
# we are done but we keep the container by waiting on signals from the mongo task echo "REPLICA SET ONLINE"; wait $MONGOD_PID;
```

Alternatively, you can create your Dockerfile in the same location with a different name and specify the filename when you build the image. Make sure to specify the variables in the Dockerfile such as the 'MONGO*REPLICA_PORT' and the 'ROOT_USERNAME' and 'PASSWORD'.
Build the container with `docker build . -t mongo-replica`. This command builds the image using the specifications in the Dockerfile located in the current directory and tags in as *mongo-replica*. Once the image is done building, we can run it, specifying the required environment variables with the following command.
`docker run -p 27017:27017 -e MONGO_INITDB_ROOT_USERNAME={username} -e MONGO_INITDB_ROOT_PASSWORD={password} mongo-replica:latest`. After the initialisation process is complete, you should see the line `REPLICA SET RUNNING`. You can check that the container is up and running with `docker ps`.
![MongoDB Container Running](https://res.cloudinary.com/ta1da-cloud/image/upload/v1668155906/realm/tutorials/next-docker-nginx/MongoDB_Running_Container_j4nwkp.png)
Once the MongoDB container is running, we should be able to install Prisma Client and generate the client that is tailored for our models. Install the client with: `npm install @prisma/client`. You may need to manually generate the client, which can be done by adding the following to your \_package.json* file.

```json
"prisma:format": "prisma format",
"prisma:generate": "prisma generate"
```

Run `npm run prisma:generate` to generate the client. If everything is set up correctly, you should see the following output:
![Prisma Generate Successful](https://res.cloudinary.com/ta1da-cloud/image/upload/v1668155909/realm/tutorials/next-docker-nginx/Prisma_Generate_Successful_lqstsh.png)

# Setting up API Routes for Data Fetching

We can also use file-system routing to set up API routes to retrieve data from our database. In the **/pages/api** folder, create a new file called _posts.ts_.
![Posts API file](https://res.cloudinary.com/ta1da-cloud/image/upload/v1668155909/realm/tutorials/next-docker-nginx/Posts_API_File_m1pouc.png)
As we will be exporting the static files from our application to serve with Nginx, we must deal with some of the limitations. One of these is that we cannot use `getServerSideProps`, which means that we lose some of the benefits of SSR and we must perform client-side data fetching. In the _index.tsx_ file, add a few lines of code to fetch the API data using the `useEffect` hook. We can also use the `useSWR` hook to fetch our data, and this gives us some additional functionality, too.
![Clientside Fetching](https://res.cloudinary.com/ta1da-cloud/image/upload/v1668155909/realm/tutorials/next-docker-nginx/Client-side_Fetching_da5fgr.png)
Since the database is empty at this point, we can seed it with some sample data. First, create a _seed.ts_ file inside your project directory -- mine is in the **prisma** folder. Import `PrismaClient` and create two posts that will be seeded to the database. Part of the _seed.ts_ file is shown below.

```javascript
async function main() {
  const intro = await prisma.post.create({
    data: {
      name: "TOAA",
      message: "Welcome to my little web app.",
    },
  });

  const intro1 = await prisma.post.create({
    data: {
      name: "TOAA",
      message: "Leave a nice, little message for me",
    },
  });
  console.log({ intro, intro1 });
}
```

To seed the command, we must add prisma.seed to the _package.json_ file as shown below.

```json
"prisma":
{     "seed":
"ts-node --compiler-options {"module":"CommonJS"} prisma/seed.ts"
},
```

We seed the database with the `npx prisma db seed` command. If you get an error message, make sure that you have `ts-node` installed. Once seeding the database has completed successfully, you can run the web app and see the results.
![Web App with posts](https://res.cloudinary.com/ta1da-cloud/image/upload/v1668156305/realm/tutorials/next-docker-nginx/App_with_data_ewuon0.png)

# Setting up Nginx

We are not going to go into detail about Nginx and all it's many features. The most important part, for now, is understanding the configuration file. Create an _nginx.conf_ file inside your project directory. Nginx modules are controlled by directives as specified in the config file. Directives can be simple directive or block directive. A simple directive consists of a name and parameters separated by spaces ending with a semi-colon (;). A block directive has a similar structure but ends with a set of additional instructions surrounded by braces. A block directive that contains other directives is known as a context. As you can see below, the `server` directive resides inside the main context. Inside this directive, we specify the listening port and also the location context with details about where to find the files.

```conf
server {
 listen 80;

 location / {
        root /usr/share/nginx/html/;
    include /etc/nginx/mime.types;
   try_files $uri $uri/ /index.html;
  } }
```

We'll be using multi-stage builds to containerise our Next.js application along with Nginx inside the image. The full Dockerfile is below, with comments to explain each line.

```dockerfile # using staged builds
FROM node:18-buster as builder
# make the directory where the project files will be stored
RUN mkdir -p /usr/src/next-nginx
# set it as the working directory so that we don't need to keep referencing it
WORKDIR /usr/src/next-nginx
# Copy the package.json file
COPY package.json package.json
# install project dependencies
RUN npm install
# copy project files
# make sure to set up .dockerignore to copy only necessary files
COPY . .
# run the build command which will build and export html files
RUN npx prisma db seed && npm run build

# bundle static assets with nginx
FROM nginx:1.21.0-alpine as production
ENV NODE_ENV production
# remove existing files from nginx directory
RUN rm -rf /usr/share/nginx/html/*
# copy built assets from 'builder' stage
COPY --from=builder /usr/src/next-nginx/out /usr/share/nginx/html
# add nginx config
COPY nginx.conf /etc/nginx/conf.d/default.conf
# expose port 80 for nginx EXPOSE 80
# start nginx
CMD ["nginx", "-g", "daemon off;"]
```

The base image for Stage 1 is `node:18-buster`, even though you can use an older version of Node. As you can see from the last line of Stage 1, we run the `build` command on our project to generate the static files and store them inside the **out** folder. An important step is to add **node_modules** to our _.dockerignore_ file to ensure that we don't copy all the large dependency files as that will slow down the image build time.
In Stage 2, we use `nginx:1.21.0-alpine` as the base image. We remove the default _index.html_ file from **/nginx/html/** directory before adding the static files from out project's output folder. We reference the files in Stage 1 using the tag `--from=builder`.
As we did earlier, we build the Dockerfile with `docker build . -t next-nginx`.

# Service Startup with Docker Compose

To streamline the process of getting all our services up and running, we can create a docker compose file with all the instructions to run our containers. We have a basic _docker-compose.yml_ file that starts up two services using the two images that we just built -- `next-nginx` and `mongo-replica`. It is important to make sure that we use port 80 inside the container as that is the port on which Nginx listens. We can still use port 3000 outside the container and access our app on the same port. The full _docker-compose.yml_ file is shown below.

```yml
version: "3.9"
services:
# this service should use the web image after you build it
 web:
image: next-nginx:dev
  ports:
   - "3000:80"
  environment:
    NODE_ENV: development
# this service is the database service using mongo from docker hub
 mongo:
  image: mongo-replica:latest
  restart: always
  ports:
  - "27027:27017"
 environment:
   MONGO_INITDB_ROOT_USERNAME: root
    MONGO_INITDB_ROOT_PASSWORD: password
```

After running the command `docker compose up`, the web app should be running and accessible via `http://localhost:3000`.

# Conclusion

We covered a lot in this tutorial, including working with Prisma and Next.js, Docker, and Nginx. I hope that you have learned something new and that this tutorial has been worth following. If you had any problems, check out the [Github repo](https://github.com/tmunongo/next-messages) for the full code. Feel free to share it with anyone who might benefit from the topics that I've covered here. I hope that this inspires you to go out and have fun with these tools, tweaking things here and there to deepen your understanding and create awesome digital experiences.
