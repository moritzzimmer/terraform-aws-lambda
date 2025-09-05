exports.handler = async function (event, context) {

    console.debug({ event, context })
    console.info("Hello from Lambda!")
    console.warn("This is a warning message!")

    return context.logStreamName
}