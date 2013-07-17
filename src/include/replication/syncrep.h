/*-------------------------------------------------------------------------
 *
 * syncrep.h
 *	  Exports from replication/syncrep.c.
 *
 * Portions Copyright (c) 2010-2013, PostgreSQL Global Development Group
 *
 * IDENTIFICATION
 *		src/include/replication/syncrep.h
 *
 *-------------------------------------------------------------------------
 */
#ifndef _SYNCREP_H
#define _SYNCREP_H

#include "access/xlogdefs.h"
#include "utils/guc.h"

#define SyncRepRequested() \
	(max_wal_senders > 0 && synchronous_commit > SYNCHRONOUS_COMMIT_LOCAL_FLUSH)

#define SyncTransRequested() \
	(max_wal_senders > 0 && synchronous_transfer > SYNCHRONOUS_TRANSFER_COMMIT)

#define IsSyncRepSkipped() \
	(max_wal_senders > 0 && synchronous_transfer ==  SYNCHRONOUS_TRANSFER_DATA_FLUSH)

/* SyncRepWaitMode */
#define SYNC_REP_NO_WAIT					-1
#define SYNC_REP_WAIT_WRITE					0
#define SYNC_REP_WAIT_FLUSH					1
#define SYNC_REP_WAIT_DATA_FLUSH	2

#define NUM_SYNC_REP_WAIT_MODE				3

/* syncRepState */
#define SYNC_REP_NOT_WAITING					0
#define SYNC_REP_WAITING						1
#define SYNC_REP_WAIT_COMPLETE					2

typedef enum
{
	SYNCHRONOUS_TRANSFER_COMMIT,		/* no wait for flush data page */
	SYNCHRONOUS_TRANSFER_DATA_FLUSH,	/* wait for data page flush only
										 * no wait for WAL */
	SYNCHRONOUS_TRANSFER_ALL	        /* wait for data page flush */
}	SynchronousTransferLevel;

/* user-settable parameters for synchronous replication */
extern char *SyncRepStandbyNames;

/* user-settable parameters for failback safe replication */
extern int	synchronous_transfer;

/* called by user backend */
extern bool SyncRepWaitForLSN(XLogRecPtr XactCommitLSN,
		bool ForDataFlush, bool Wait);

/* called at backend exit */
extern void SyncRepCleanupAtProcExit(void);

/* called by wal sender */
extern void SyncRepInitConfig(void);
extern void SyncRepReleaseWaiters(void);

/* called by checkpointer */
extern void SyncRepUpdateSyncStandbysDefined(void);

/* called by various procs */
extern int	SyncRepWakeQueue(bool all, int mode);

extern bool check_synchronous_standby_names(char **newval, void **extra, GucSource source);
extern void assign_synchronous_commit(int newval, void *extra);
extern void assign_synchronous_transfer(int newval, void *extra);

#endif   /* _SYNCREP_H */
