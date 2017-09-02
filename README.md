# Minimal SFTP Server within a Docker container

This is an Alpine based image, which installs the very minimum needed to run an
SFTP server.

It was originally created as an SFTP endpoint for 
[Duplicacy](http://duplicacy.com/).


## General Design

Each SFTP user gets a user account within the container. No account within the
container gets any passwords set, so the only ways to access the container are
using `docker exec`, or via the SSH server listening on port 2022.

The SSH server is configured to require public key authentication for all
logins, and all logins are restricted to sftp only. Additionally, each login
is chroot'ed to a directory containing only the user's SFTP files and 
`authorized_keys` file. 

Basically there's multiple layers of protection to make exposing this as an
Internet facing service as safe as possible. Usual disclaimers apply about
taking responsibility for your own security.


## Using this container

Build the container with

```
docker build -t caelor/sftp-server .
```

Run the container with

```
docker run -d --name sftp-server -v /var/sftp-server:/data caelor/sftp-server
```

Manage users by creating a file in `/var/sftp-server/users/<username>.pub` -
the file should contain a public key per line (e.g. exactly like an 
`authorized_keys` file). The owner UID of the file will be the uid of the user
within the container. Files owned by root will be ignored.

The files are polled for changes roughly every 20 seconds.

The SFTP files are created within `/data/userdata/<username>/sftp`


## Structure of the `/data` volume

The `/data` volume is structured specifically to support the OpenSSH server
chroot approach, as well as containing other persistence data.


### `/data/server`
This holds the RSA and ECDSA keys for the SSH server.

### `/data/users`
This is intended to be managed from outside the container. It contains a file
per user, and is polled by the container to grant or deny access. Files should
have a `.pub` suffix.

- **User Name** - the basename of the file (without `.pub`) defines the 
  username
- **Permitted Public Keys** - the contents of the file are the public keys used 
  for authentication of the user
- **UID** - the UID of file owner defines the UID of the user within the
  container. Root owned files are ignored.

**Caution**: You need to make sure that each UID is unique, or undefined things
will happen within the container.

### `/data/userdata/<username>`
A directory for each configured user, which is owned by root. This becomes the
chroot directory for the logged in user.

### `/data/userdata/<username>/authorized_keys`
The `authorized_keys` file for the specified user.

### `/data/userdata/<username>/sftp`
The directory within the chroot that the `internal-sftp` subsystem is
instructed to use as the sftp-root. It's owned by the uid allocated to the
user, with a group of 1001 ("sftpusers" internally).

This is where the data that the user actually uploads ends up.


