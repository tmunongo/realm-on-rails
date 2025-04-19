---
title: Setting up an Apollo GraphQL server in Next.js 13
author: Tawanda Munongo
bio: I spend most of my days learning about and building software systems. When I inevitably learn something new, I come here and write about it. Once in a while, I might throw in some fiction and philosophy.
linkedin: https://linkedin.com/in/tawanda-munongo
github: https://github.com/tmunongo
cover: http://res.cloudinary.com/ta1da-cloud/image/upload/v1676037314/realm/covers/Setting%20up%20an%20Apollo%20GraphQL%20server%20in%20Next.js%2013.png
tags: ["Tutorial", "NextJS", "GraphQL"]
description: Unlock the power of GraphQL and Next.js with this comprehensive tutorial! Learn the essentials step-by-step and build better APIs with Apollo and GraphQL.
publishDate: 2023-02-10
---

# Introduction

In this tutorial, I will show you how to set up Next.js 13 to serve a GraphQL API with Apollo Server.

## What is GraphQL

GraphQL is a query language for reading and mutating data in APIs. It is also a server-side run-time technology for fulfilling queries with existing data. GraphQL was developed at Facebook (now Meta) to deal with some challenges encountered in implementing the News Feed.

## Why Use GraphQL over REST

GraphQL has risen to prominence as an alternative to the _Representational State Transfer (REST)_ paradigm which stores data entities under URLs on a server. In comparison, GraphQL uses a schema to allow back-end developers to define the structure of the data to be returned by the server. Then, using this schema, a front-end consumer can explore the available data and request specific data. It solves the problem of over-fetching encountered with REST APIs because it allows the client to specify exactly which data should be returned in a format that resembles _JavaScript Object Notation (JSON)_. However, GraphQL creates a tight coupling between the front and back end that makes it more suitable for use when the front and back-end teams are working closely.

# Set Up

For this tutorial, I will assume that you are familiar with Next.js and GraphQL. You can follow the tutorial from the beginning or clone the [starter repo](https://github.com/tmunongo/quotible-next) **initial branch** from GitHub with all the dependencies already installed. We will be building a simple quotes app.

We will use `_create-next-app_` to initialise a new Next.js project. Run the command `npx create-next-app [your desired name]` and follow the prompts to configure the project.

![https//rescloudinarycom/ta1dacloud/image/upload/v1676035067/realm/tutorials/nextjsgraphql/projectinithwnsr0png](https://res.cloudinary.com/ta1da-cloud/image/upload/v1676035067/realm/tutorials/nextjs-graphql/project-init_hwnsr0.png)

Then, we install the required dependencies using the command below:

```bash
npm install @apollo/client @prisma/client apollo-server-micro graphql micro-cors
```

We will also install some dev dependencies.

```bash
npm install -D @types/micro-cors prisma ts-node
```

This should be all but if we need anything else we can always install it later.

# Creating the Apollo Client

According to their website, Apollo Client is a _'state management library for JavaScript that enables you to manage both local and remote data with GraphQL'_. We will use it to fetch application data and keep the UI up-to-date.

In your project directory, create a folder called _lib_. This is where we will store various configuration files for our project. Inside this folder create a file called _client.ts_.

First, we create an instance of HttpLink, passing in the URI for our GraphQL server (we'll configure this next). Then, we create an instance of _ApolloClient_ by passing in the HttpLink instance and creating a new instance of _InMemoryCache_. This is used by Apollo Client to cache the results of any given query.

![https//rescloudinarycom/ta1dacloud/image/upload/v1676035064/realm/tutorials/nextjsgraphql/apolloclienthas66fpng](https://res.cloudinary.com/ta1da-cloud/image/upload/v1676035064/realm/tutorials/nextjs-graphql/apollo-client_has66f.png)

# Create the GraphQL server

We will set up the GraphQL server in our _pages/api_ folder to handle our requests. When we create an instance of ApolloServer, we must pass in the type definitions from the GraphQL schema and at least one resolver. We can also pass into the context anything that we wish to be accessible throughout the server. We can create a _graphql.ts_ file inside the _/api_ folder which we will return to after creating the schema and resolvers.

In the root of your project, create a folder called _graphql_. This is where we will store everything that has to do with GraphQL. Inside that folder, create a _schema.ts_ file where we will define the schema. In the schema, we can define types for our data models and the various queries and mutations that our server will resolve. This is the most important step when we use the schema-first approach to designing GraphQL APIs. In our case, we will have a single **Quote** data model, and two queries to fetch a list of quotes and a single quote by its ID.

![https//rescloudinarycom/ta1dacloud/image/upload/v1676035069/realm/tutorials/nextjsgraphql/typedefsb0zntgpng](https://res.cloudinary.com/ta1da-cloud/image/upload/v1676035069/realm/tutorials/nextjs-graphql/type-defs_b0zntg.png)

Our quote model has 4 properties, an ID that will be automatically assigned by the database, a string tag, an author, and the content of the quote. All fields are required. The quotes query will return an array of quote objects. We can also return a single quote by passing in an ID.

Within the same folder, create two folders for the resolvers and the methods. This is where we will define the methods to handle our API requests.

![https//rescloudinarycom/ta1dacloud/image/upload/v1676035226/realm/tutorials/nextjsgraphql/graphqlfolderuf58snpng](https://res.cloudinary.com/ta1da-cloud/image/upload/v1676035226/realm/tutorials/nextjs-graphql/graphql-folder_uf58sn.png)

We create an _index.ts_ file inside the resolvers folder. It will help with organising our methods if we ever decide to add more resolvers to our project.

![https//rescloudinarycom/ta1dacloud/image/upload/v1676035068/realm/tutorials/nextjsgraphql/resolversqm3el3png](https://res.cloudinary.com/ta1da-cloud/image/upload/v1676035068/realm/tutorials/nextjs-graphql/resolvers_qm3el3.png)

As you can see above, if our project had mutations or any other resolvers, it would be very easy to add and manage them.

In our _query.ts_ file, we will implement the methods to retrieve our data from the database. We will be using PrismaORM to run our database queries, so we must make an instance of Prisma Client available to our resolvers via the context.

# Initialise Prisma and Create Context

We must first initialise Prisma with the command `npx prisma init`. If you cloned the starter, you do not need to run this command. Running _prisma init_ creates a _prisma_ folder in the parent directory with a _prisma.schema_ file and creates or modifies our _.env_ file.

Modify the prisma schema file by changing the provider to mongodb. Prisma can be configured to work with a number of different databases. Just as we did with the GraphQL schema, we will also define the shape of our data as shown below.

![https//rescloudinarycom/ta1dacloud/image/upload/v1676035063/realm/tutorials/nextjsgraphql/prismaschemaiu6i7npng](https://res.cloudinary.com/ta1da-cloud/image/upload/v1676035063/realm/tutorials/nextjs-graphql/prisma-schema_iu6i7n.png)

After we create the schema, we must also add some scripts to our _package.json_ that we will use to interact with the database.

![https//rescloudinarycom/ta1dacloud/image/upload/v1676035064/realm/tutorials/nextjsgraphql/prismascriptsgqu42zpng](https://res.cloudinary.com/ta1da-cloud/image/upload/v1676035064/realm/tutorials/nextjs-graphql/prisma-scripts_gqu42z.png)

Run the Prisma Generate command, `npm run prisma:generate` to generate the Prisma Client and types according to our schema. The seed command will be used later to add sample data to our database.

Now, we can create our context. Create a _context.ts_ file inside the _/lib_ folder. Inside this file we will create an instance of Prisma Client and use _createContext()_ to make it available to the resolvers.

![https//rescloudinarycom/ta1dacloud/image/upload/v1676035065/realm/tutorials/nextjsgraphql/createcontextbnkvo6png](https://res.cloudinary.com/ta1da-cloud/image/upload/v1676035065/realm/tutorials/nextjs-graphql/create-context_bnkvo6.png)

We can return to our _query.ts_ file and import _Context_ from _context.ts_. We will define two query methods to handle retrieving a list of quotes and a single quote. These are the queries that we have defined in our GraphQL schema.

![https//rescloudinarycom/ta1dacloud/image/upload/v1676035069/realm/tutorials/nextjsgraphql/queryresolverszwz6aqpng](https://res.cloudinary.com/ta1da-cloud/image/upload/v1676035069/realm/tutorials/nextjs-graphql/query-resolvers_zwz6aq.png)

# Finalise the GraphQL Server

After creating our resolvers and schema, we can return to the _graphql.ts_ file and configure the GraphQL server.

The first step is to update the Next.js page config and set bodyParser to false. This allows our Apollo Server to read the request body instead of Next.js. After that, we create an instance of Apollo Server. We configure the ApolloServer object by adding the context, type definitions, and resolvers. We also set _introspection_ to true. Introspection allows us to query the server about the underlying schema. Ideally, this should be false in a production environment. We can use the start command to start our server.

![https//rescloudinarycom/ta1dacloud/image/upload/v1676035062/realm/tutorials/nextjsgraphql/apolloserverqxdzvmpng](https://res.cloudinary.com/ta1da-cloud/image/upload/v1676035062/realm/tutorials/nextjs-graphql/apollo-server_qxdzvm.png)

We also need to configure _cors_ using the `micro-cors` package. CORS is an HTTP-based header protocol that allows a server to control which origins can access its resources. In order to use the Apollo Studio, we must allow requests from the Apollo Studio origin. We will also allow it to set certain headers.

![https//rescloudinarycom/ta1dacloud/image/upload/v1676035065/realm/tutorials/nextjsgraphql/corsconfigoihmuvpng](https://res.cloudinary.com/ta1da-cloud/image/upload/v1676035065/realm/tutorials/nextjs-graphql/cors-config_oihmuv.png)

# Testing the Server

At this point, we should be able to access our server at `http://localhost:3000/api/graphql`. From here we can introspect our schema and test the database. If you downloaded the starter repo, you can build the Mongo Replica Set image using the Dockerfile and load up a container with `docker compose up`. Or, if you have MongoDB already installed on your machine, you can seed the database using the _seed.ts_ file in the repo with the command `npx prisma db seed`. After seeding the database, you can run a query in the Apollo Playground to see if you can retrieve some data from the database.

![https//rescloudinarycom/ta1dacloud/image/upload/v1676035227/realm/tutorials/nextjsgraphql/apolloplaygroundzg3ihqpng](https://res.cloudinary.com/ta1da-cloud/image/upload/v1676035227/realm/tutorials/nextjs-graphql/apollo-playground_zg3ihq.png)

![https//rescloudinarycom/ta1dacloud/image/upload/v1676035063/realm/tutorials/nextjsgraphql/graphqlquerypl0p2hpng](https://res.cloudinary.com/ta1da-cloud/image/upload/v1676035063/realm/tutorials/nextjs-graphql/graphql-query_pl0p2h.png)

We can also write the same queries and store them in the _/graphql/methods/query.ts_ file to use them in our application. We can call the `GET_QUOTES` method inside _getServerSideProps_ to use SSR in our app.

![https//rescloudinarycom/ta1dacloud/image/upload/v1676035068/realm/tutorials/nextjsgraphql/ssrqueryivfa3epng](https://res.cloudinary.com/ta1da-cloud/image/upload/v1676035068/realm/tutorials/nextjs-graphql/ssr-query_ivfa3e.png)

# Conclusion

In conclusion, I hope that this tutorial has been helpful in guiding you through the process of setting up a GraphQL server in Next.js. By following the steps outlined in this tutorial, you should now have a solid understanding that will allow you to use GraphQL in your own Next.js projects. If there's anything you missed, you can also find the completed project on the `main` branch of the GitHub repo, including a sample home page showing how to query the GraphQL server. I encourage you to continue practising and exploring new programming technologies to enhance your skills. If you have any questions or feedback, feel free to reach out to me on Twitter (@edtha3rd). Thanks for reading!
