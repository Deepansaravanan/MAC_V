# Reconfiguration Methodology

Configuration values will be captured in runtime-accessible registers. The mode controller will validate and decode requested policies; the reconfiguration controller will coordinate safe application to the datapath. Mode changes must not require RTL resynthesis. The future implementation must specify whether a change is accepted only while idle or is otherwise transaction-safe.

