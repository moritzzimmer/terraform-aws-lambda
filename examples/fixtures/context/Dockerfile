FROM public.ecr.aws/serverless/extensions/lambda-insights:12 AS lambda-insights

FROM public.ecr.aws/lambda/nodejs:12
COPY --from=lambda-insights /opt /opt
COPY app.js /var/task/
