Flight Blender is an open-source backend and data-processing engine designed to support standards-compliant UTM (Unmanned Traffic Management) services. It adheres to the latest regulations for UTM/U-Space in the EU and other jurisdictions. With Flight Blender, you can:

Implement a Remote ID “service provider” compatible with the ASTM-F3411 Remote ID standard, along with Flight Spotlight, an open-source Remote ID Display Application.
Use an open-source implementation of the ASTM F3548 USS-to-USS standard, compatible with EU U-Space regulations for flight authorization.
Interact with interoperability software like interuss/dss to exchange data with other UTM systems.
Process geo-fences using the ED-269 standard.
Monitor conformance and send operator notifications.
Aggregate flight traffic feeds from various sources, including geo-fences, flight declarations, and air-traffic data.
Configure Blender to act as a Surveillance SDSP per the ASTM F3623-23 standard.
Implement alerts / near misses per the ASTM F3442 standard


Key Features

DSS Connectivity
Connect and retrieve data such as Remote ID information or perform strategic de-confliction and flight authorization.

Flight Tracking
Ingest flight tracking feeds from sources like ADS-B, live telemetry, and Broadcast Remote ID. Outputs a unified JSON feed for real-time display.

Geofence Management
Submit geofence to Flight Blender, which can then be transmitted to Spotlight for visualization.

Flight Declaration
Submit future flight plans (up to 24 hours in advance) using the ASTM USS-to-USS API or as a standalone component. Supported DSS APIs are listed below.

Network Remote ID
Compliant with ASTM standards, this module can act as a “display provider” or “service provider” for Network Remote ID.

Operator Notifications
Send notifications to operators using an AMQP queue, enabling real-time alerts for flight updates, conformance issues, or other critical events.

Conformance Monitoring
Monitor flight paths against declared 4D volumes for conformance and report outputs.

Surveillance SDSP
Blender conforms to the requirements for Surveillance supplemental data service providers (SDSPs) and associated equipment and services.

Detect, Alert and Avoid
Flight Blender implements the Detect Alert and Avoid standard F3442


Can you explore these repos I have attached and create a detailed spec for each of this features on how they can be implemented in the spotlight, the API endpoints in the Blender, that is responsible for these features. I am new to openutm, so make this as much detailed with diagram as you can

