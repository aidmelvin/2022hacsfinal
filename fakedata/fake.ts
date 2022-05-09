import { DataTypes, Sequelize } from "sequelize";
import faker from "@faker-js/faker"

/**
 * This script connects to the postgres database on the container and adds a
 * table with fake user information (name, phone #, address, email, and credit
 * card number) for use as honey.
 */

const FAKE_ENTRIES_MIN = 100
const FAKE_ENTRIES_MAX = 150

function getRndInteger(min: number, max: number) {
    return Math.floor(Math.random() * (max - min) ) + min;
}

(async () => {
    const sql = new Sequelize("postgres://postgres:postgres@localhost:5432/postgres");
    await sql.authenticate();
    console.log("Authenticated with DB");

    // Initialize table
    const User = sql.define("User", {
        name: {
            type: DataTypes.STRING,
        },

        phoneNumber: {
            type: DataTypes.STRING
        },

        address: {
            type: DataTypes.STRING
        },

        email: {
            type: DataTypes.STRING
        },

        creditCardNumber: {
            type: DataTypes.STRING
        }
    })

    await User.sync();
    console.log("User table created");

    // Generate fake data
    const numberEntriesToAdd = getRndInteger(FAKE_ENTRIES_MIN, FAKE_ENTRIES_MAX);
    const userObjs = []

    for (var i = 0; i < numberEntriesToAdd; i++) {
        userObjs.push({
            name: `${faker.name.firstName()} ${faker.name.middleName()} ${faker.name.lastName()}`,
            phoneNumber: faker.phone.phoneNumber(),
            address: faker.address.streetAddress(),
            email: faker.internet.email(),
            creditCardNumber: faker.finance.creditCardNumber()
        })
    }

    // Create users
    await User.bulkCreate(userObjs)
    console.log("Added users!")

    // Save data and close DB connection
    await sql.close()
    console.log("Fake data successfully added!");
})()
