package util

import (
	"context"

	"go.opentelemetry.io/contrib/detectors/aws/ecs"
	"go.opentelemetry.io/otel/sdk/trace"
	mtrace "go.opentelemetry.io/otel/trace"
)

type OpenTelemetry struct {
	TracerProvider *trace.TracerProvider
	Tracer         mtrace.Tracer
}

func (u *OpenTelemetry) CreateEcsTracerProvider() {
	ec2ResourceDetector := ecs.NewResourceDetector()
	resource, _ := ec2ResourceDetector.Detect(context.Background())

	// Associate resource with TracerProvider
	tracerProvider := trace.NewTracerProvider(
		trace.WithResource(resource),
	)

	u.TracerProvider = tracerProvider
}
