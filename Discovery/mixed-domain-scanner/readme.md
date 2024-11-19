# Challenges

_Noted from Slack discussions_.

- Many of the linux servers don't have a DNS name attribute in Active Directory. If the FQDN of the server is other than the discovery source's FQDN, the machine scan would fail as SS wouldn't be able to find the machine. Ask that those are updated with a DNS value in AD for machines failing as you go
- If the AD-Linux bridge is flakey at times it can cause various issues with SS trying to perform discovery on the device(s)

![image](https://user-images.githubusercontent.com/11204251/108533772-f70aa000-729e-11eb-92f2-ef69d8aec9ea.png)
