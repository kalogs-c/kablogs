---
title: "\"Super polymorphism\" with Typescript plus dynamic imports"
date: 2023-04-30T14:18:03-03:00
draft: false
description: Manage application with different modules without import all of them
tags:
    - Typescript
    - Polymorphism
---

Imagine that you're writing an application that has tons of modules, but you only need to import one of them per run, how import exclusively the libraries that this given module uses? 
In this post, I'll show how I did when I was exposed to this situation twice, one of them writing a web scrapper that scraps content from different websites using [Puppetter](https://pptr.dev/). 
I'll show you a simple CLI app that gets the module name from the command line as an argument. 
The modules that we'll use are [PokeAPI](https://pokeapi.co/) and [Digimon API](https://digimon-api.vercel.app/). All the source code will be available on GitHub.

## Creating project
First, let's create our typescript project, note that I'm using [pnpm](https://pnpm.io/), but you can use your favorite package manager:

```sh
# Create package.json
❯ pnpm init 

# Install typescript dev dependencies
❯ pnpm add -D typescript @types/node ts-node

# Install Axios lib for http requests
❯ pnpm add axios

# Create tsconfig.json
# For this part you can just copy my tsconfig on GitHub, I've made a few changes like the output directory 
# but if you want to customize yourself, you can run
❯ npx tsc --init

# Create src folder, that will include all our ts files
❯ mkdir src

# Create main file, our entry point
❯ touch src/main.ts

# Create DataSources folder, which will store all our polymorphic classes
❯ mkdir src/DataSources

# Inside it we'll create a DataSource.ts file, which is our skeleton interface
# All the other classes will implement this interface
❯ touch src/DataSources/DataSource.ts

# Now we can create the modules files.
# I will create two, one for the PokeAPI and the other for DigimonAPI
❯ touch src/DataSources/Pokemon.ts src/DataSources/Digimon.ts

# And now you can open the project on your favorite text editor/IDE
# I use neovim btw
❯ vim
```

The project structure will look to something similar to this
```
Project
├── node_modules
├── src
│   └── DataSources
│       ├── DataSources.ts
│       ├── Pokemon.ts
│       └── Digimon.ts
├── package.json
└── tsconfig.json
```

## Main Interface and types
We'll start adding the main interface to DataSource.ts.
```ts
/* src/DataSources/DataSource.ts */
interface DataSource {
  New: () => Promise<DataSource>;

  getMonster: (name: string) => Promise<MonsterData>;
}

// Don't forget to export
export default DataSource;
```

The `New()` function will act like a async contructor of our class, some situations we have to do async stuff before properly instantiated the object, and creating a function to do this will create a pattern and make our code more readable. Note that the expected return of this method is a [`Promise`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Promise) that contains something that implements `DataSource` when resolved.

The `getMonster()` method returns a [`Promise`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Promise) that when resolved returns an instance of `MonsterData` that describe the data that we want to retrieve from the APIs, based on the monster name.

You've probably noticed that the type `MonsterData` does not exist yet, so let's create it. This type will be the target of our modules, a global acceptable type that all the modules have to parse data to. You can create it on a separated file, but I'll still use the same one.

```ts
/* src/DataSources/DataSource.ts */
export type MonsterData = {
  name: string,
  img: string,
}
```

## Implementing the Interface

I'll start with PokeAPI consumer because Pokémon is better than Digimon 😝

```ts
/* src/DataSources/Pokemon.ts */
import axios, { AxiosInstance } from "axios";
import DataSource, { MonsterData } from "./DataSource";

class Pokemon implements DataSource {
  private client: AxiosInstance;

  constructor() {
    this.client = axios.create({
      baseURL: "https://pokeapi.co/api/v2/pokemon",
      timeout: 2000,
      headers: {
        "Content-Type": "application/json",
      },
    })
  }

  public async New(): Promise<Pokemon> {
    return this;
  }

  public async getMonster(pokemonName: string): Promise<MonsterData> {
    const pokeApiResponse = await this.client.get(`/${pokemonName}`);

    const pokemonData = pokeApiResponse.data;

    return {
      name: pokemonName.charAt(0).toUpperCase() + pokemonName.slice(1),
      img: pokemonData.sprites.front_default,
    }
  }
}

// Don't forget to export without instantiated the class
// For example, dont't type `export default new`
export default Pokemon;
```

Really simple file, but has four things that we may notice. 

### 1. First is that our class [implements](https://www.typescriptlang.org/docs/handbook/interfaces.html#implementing-an-interface) the `DataSource` interface.
```ts
class Pokemon implements DataSource {
    ...
}
```

### 2. The `New()` "async contructor"

Note that this function just return our object, but if we had the need to do some asynchronous calls before instantiated the class, we would do here. 
Just to examplify, imagine that before do the http requests we had to log in and get a token on another endpoint and save on our class. Would be something like this

```ts
public async New(): Promise<DataSource> {
  const token = await getToken();
  this.client = axios.client({
    ...,
    Headers: {
      ...,
      "Authorization": `Bearer ${token}`
    }
  });
}
```

### 3. Data modeling

Check `getMonster()` method, we always return a [`Promise`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Promise) with `MonsterData` type inside it, that means that we always have to parse the data model received from the api to this expected model.
And It's recomended that you create custom types that describes which kind of data we expect to receive from the http request.
I didn't do that because this is a really simple project.

### 4. Exporting our class

I'm exporting the class, and not the object. 
Notice that `export default Pokemon` is different from `export default new Pokemon`.
There is no right or wrong way here, but be sure that all your classes follow the same pattern.
On this project all classes we will export without the `new` keyword.

## Digimon implementacion

This one will be basically the same thing that we did on the Pokemon.ts file

```ts
/* src/DataSources/Pokemon.ts */
import axios, { AxiosInstance } from "axios";
import DataSource, { MonsterData } from "./DataSource";

class Digimon implements DataSource {
  private client: AxiosInstance;

  constructor() {
    this.client = axios.create({
      baseURL: "https://digimon-api.vercel.app/api/digimon/name/",
      timeout: 2000,
      headers: {
        "Content-Type": "application/json",
      },
    })
  }

  public async New(): Promise<Digimon> {
    return this;
  }

  public async getMonster(digimonName: string): Promise<MonsterData> {
    const digimonApiResponse = await this.client.get(`/${digimonName}`);

    const [digimonData] = digimonApiResponse.data;

    return {
      name: digimonData.name,
      img: digimonData.img,
    }
  }
}

export default Digimon;
```

The only thing different here is how we consume the API, and even that is kinda similar

## Main file and dynamic import

In our main.ts file let's write our dynamic code

```ts
/* src/main.ts */
import DataSource from "./DataSources/DataSource"

(async () => {
  const [dsName, monsterName] = process.argv.slice(2);

  // Return error when no param are passed
  if (!dsName || !monsterName) throw new Error("Usage: node main.js <DataSouce> <MonsterName>");

  const dataSource: DataSource = await (
    new (await import(`./DataSources/${dsName}`)).default
  ).New()

  console.table(await dataSource.getMonster(monsterName));
})()
```

So let's jump to the part where things happen

```ts
const dataSource: DataSource = await ( 
  new (await import(`./DataSources/${dsName}`)).default // Import and instantiated the class
).New() // Call the method that do async stuff
```

Explaining each part we have

```ts
await import(`./DataSources/${dsName}`)

// Returns
{ default: class }
```

This block of code returns an object with all the exported stuff inside it, the one that matters for us is the default one, that's why we use the `.default` after the close parenthesis, and as returns a class, we use the `new` keyword to instantiate it.

The first await is connected to the `.New()` method, which returns a [`Promise`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Promise) with the Object instantiated inside of it.

Now the class are totally instantiated, and we can call the methods inside the `DataSource` interface. We do this on this block

```ts
console.log(await dataSource.getMonster(monsterName));
```

## Testing
Now, if we execute the project by passing arguments through the command line.
We need to pass the module and the monster name.
We will get this result

### Pokémon
```sh
❯ npx ts-node src/main.ts Pokemon snorlax
```
```json
{
  name: "Snorlax",
  img: "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/143.png"
}
```

### Digimon
```sh
❯ npx ts-node src/main.ts Digimon patamon
```
```json
{
  name: "Patamon",
  img: "https://digimon.shadowsmith.com/img/patamon.jpg"
}
```

Note that our first parameter is exactly our file name where we wrote the class and not the class name

## Tchau 👋

That's it for today, feel free to add something and if I made something wrong or that can be improved please tell me please. 

And remember that all the source code of this mini project is available on [GitHub](https://github.com/kalogs-c/super-polymorphism).

Tchau!!
