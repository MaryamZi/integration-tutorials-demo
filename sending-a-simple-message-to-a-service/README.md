# Sending a Simple Message to a Service

## What you'll build

Let's develop a service that allows a user to retrieve a list of doctors based on the doctor's specialization (category). The information about the doctors is retrieved from a separate microservice. 

To implement this use case, you will develop a REST service with a single resource using Visual Studio Code with the Ballerina Swan Lake extension, and then run the service. The resouce  will receive the user request, retrieve details from the backend service, and respond to the user request with the relevant doctor details.

### Concepts covered

- REST API
- HTTP client

## Let's get started!

### Step 1: Set up the workspace

Install [Ballerina Swan Lake](https://ballerina.io/downloads/) and the [Ballerina Swan Lake VSCode extension](https://marketplace.visualstudio.com/items?itemName=wso2.ballerina) on VSCode.

### Step 2: Develop the service

Follow the instructions given in this section to develop the service.

1. Create a new Ballerina project using the `bal` command and open it in VSCode.

```bash
$ bal new sending-a-simple-message-to-a-service
```

2. Introduce the source code in files with the `.bal` extension (e.g., the `main.bal` file). 

Import the 
- `ballerina/http` module to develop the REST API and define the client that can be used to send requests to the backend service
- `ballerina/log` module to log some information for each client request

```ballerina
import ballerina/http;
import ballerina/log;
```

3. Define an `http:Client` client to send requests to the backend service.

```ballerina
final http:Client queryDoctorEP = check new ("http://localhost:9090/healthcare");
```

The argument to the `new` expression is the URL for the backend service.

4. Define a record corresponding to the payload from the backend service.

```ballerina
type Doctor record {|
    string name;
    string hospital;
    string category;
    string availability;
    decimal fee;
|};
```

The payload will be an array of JSON objects, where the structure of each JSON object matches this record. Note that you can use the "Paste JSON as record" VSCode command to generate the record if you have the JSON payload.

5. Define the HTTP service (REST API) that has the resource that accepts user requests, retrieves relevant details from the backend service, and responds to the request. Use `/healthcare` as the service path (or the context) of the service which is attached to the listener listening on port `8290`. Define an HTTP resource that allows the `GET` operation on resource path `/querydoctor` and accepts the `category` (corresponding to the specialization) as a path parameter.

```ballerina
service /healthcare on new http:Listener(8290) {
    resource function get querydoctor/[string category]() {
        
    }
}
```

6. Implement the logic to retrieve and respond with relevant details.

```ballerina
service /healthcare on new http:Listener(8290) {
    resource function get querydoctor/[string category]() returns Doctor[]|http:NotFound|http:InternalServerError {
        log:printInfo("Retrieving information", specialization = category);
        
        Doctor[]|http:ClientError resp = queryDoctorEP->/[category];
        if resp is Doctor[] {
            return resp;
        }

        if resp is http:ClientRequestError {
            return <http:NotFound> {body: string `category not found: ${category}`};
        }

        return <http:InternalServerError> {body: resp.message()};
    }
}
```

- The `log:printInfo` statement logs information about the request.

```ballerina
log:printInfo("Retrieving information", specialization = category);
```

- The call to the backend is done using a remote method call expression (using `->`) which distinguishes network calls from normal method calls. [Client data binding](https://ballerina.io/learn/by-example/http-client-data-binding/) is used to directly try and bind the JSON response on success to the expected array of records.

```ballerina
Doctor[]|http:ClientError resp = queryDoctorEP->/[category];
```

- Use the `is` check to decide the response based on the response to the client call. If the client call was successful and the respond payload was an array of `Doctor`s (as expected) directly return the array from the resource. If the request failed, send a "NotFound" response if the client call failed with a 4xx status code or return an "InternalServerError" response for other failures.

```ballerina
log:printInfo("Retrieving information", specialization = category);

Doctor[]|http:ClientError resp = queryDoctorEP->/[category];
if resp is Doctor[] {
    return resp;
}

if resp is http:ClientRequestError {
    return <http:NotFound> {body: string `category not found: ${category}`};
}

return <http:InternalServerError> {body: resp.message()};
```

#### Complete source

You have successfully developed the required service.

```ballerina
import ballerina/http;
import ballerina/log;

type Doctor record {|
    string name;
    string hospital;
    string category;
    string availability;
    decimal fee;
|};

final http:Client queryDoctorEP = check new ("http://localhost:9090/healthcare");

service /healthcare on new http:Listener(8290) {
    resource function get querydoctor/[string category]() returns Doctor[]|http:NotFound|http:InternalServerError {
        log:printInfo("Retrieving information", specialization = category);
        
        Doctor[]|http:ClientError resp = queryDoctorEP->/[category];
        if resp is Doctor[] {
            return resp;
        }

        if resp is http:ClientRequestError {
            return <http:NotFound> {body: string `category not found: ${category}`};
        }

        return <http:InternalServerError> {body: resp.message()};
    }
}
```

### Step 3: Build and run the service

You can run this service by navigating to the project root and using the `bal run` command.

```bash
sending-a-simple-message-to-a-service$ bal run
Compiling source
        integration_tutorials/sending_a_simple_message_to_a_service:0.1.0

Running executable
```

### Step 4: Test the use case

Let's test the use case by sending a request to the service.

#### Start the back end service

Download the JAR file for the backend service from [here](https://github.com/wso2-docs/WSO2_EI/blob/master/Back-End-Service/Hospital-Service-JDK11-2.0.0.jar) and execute the following command to start the service:

```bash
java -jar Hospital-Service-JDK11-2.0.0.jar
```

#### Send a request

Let's send a request to the service using cURL as follows.

1. Install and set up [cURL](https://curl.haxx.se/) as your client.

2. Execute the following command.

```bash
curl -v http://localhost:8290/healthcare/querydoctor/surgery
```

#### Verify the response

You will see the response message from backend with a list of details of the available doctors.

```json
[
    {
        "name": "thomas collins",
        "hospital": "grand oak community hospital",
        "category": "surgery",
        "availability": "9.00 a.m - 11.00 a.m",
        "fee": 7000.0
    },
    {
        "name": "anne clement",
        "hospital": "clemency medical center",
        "category": "surgery",
        "availability": "8.00 a.m - 10.00 a.m",
        "fee": 12000.0
    },
    {
        "name": "seth mears",
        "hospital": "pine valley community hospital",
        "category": "surgery",
        "availability": "3.00 p.m - 5.00 p.m",
        "fee": 8000.0
    }
]
```

Now, check the terminal in which you ran the Ballerina service. You should see a log similar to the following.

```bash
time = 2023-08-15T13:01:34.022+05:30 level = INFO module = integration_tutorials/sending_a_simple_message_to_a_service message = "Retrieving information" specialization = "surgery"
```

You have now developed and deployed a simple Ballerina REST service which receives requests, logs a message, sends a request to a backend service, and responds to the original request with the response from the backend service.

## References

- [REST service](https://ballerina.io/learn/by-example/#rest-service)
- [HTTP client](https://ballerina.io/learn/by-example/#http-client)
- [Logging](https://ballerina.io/learn/by-example/#log)
