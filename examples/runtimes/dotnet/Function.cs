using Amazon.Lambda.Core;

[assembly: LambdaSerializer(typeof(Amazon.Lambda.Serialization.SystemTextJson.DefaultLambdaJsonSerializer))]

namespace LambdaDotnetExample;

public class Function
{
    public object FunctionHandler(object input, ILambdaContext context)
    {
        context.Logger.LogInformation("Processing request");
        return new
        {
            statusCode = 200,
            runtime = System.Runtime.InteropServices.RuntimeInformation.FrameworkDescription,
            architecture = System.Runtime.InteropServices.RuntimeInformation.OSArchitecture.ToString(),
            message = "Hello from .NET Lambda!"
        };
    }
}
