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
