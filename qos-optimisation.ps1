# This script creates a QoS policy for RDP Shortpath for managed networks.
# The policy applies to the application "svchost.exe" and matches UDP traffic
# with source port 3390. The DSCP value is set to 46, and the policy applies
# to all network profiles.
#
# The rollback command removes the QoS policy with the specified name.

```powershell
New-NetQosPolicy -Name "RDP Shortpath for managed networks" -AppPathNameMatchCondition "svchost.exe" -IPProtocolMatchCondition UDP -IPSrcPortStartMatchCondition 3390 -IPSrcPortEndMatchCondition 3390 -DSCPAction 46 -NetworkProfile All
```

```powershell
Rollback - Remove-NetQosPolicy -Name "RDP Shortpath for managed networks"
```