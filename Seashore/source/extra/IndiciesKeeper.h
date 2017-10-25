/*!
	@header		IndiciesKeeper
	@abstract	Provides a way to store an arbitrary number of integers.
	@discussion	These functions may be removed in the near future.
				<br><br>
				<b>License:</b> GNU General Public License<br>
				<b>Copyright:</b> Copyright (c) 2002 Mark Pazolli
*/

#import "Globals.h"

/*!
	@struct		IndiciesRecord
	@discussion	A record to which an arbitrary number of indicies may be added.
	@field		indicies
				An array of all the indicies.
	@field		length
				The number of indicies in the record.
*/
typedef struct {
	int *indicies;
	int length;
} IndiciesRecord;

/*!
	@struct		IndiciesKeeper
	@discussion	A keeper to which records can be added.
	@field		stack
				As stack containing all records.
	@field		length
				The number of records added to the keeper.
*/
typedef struct {
	IndiciesRecord *stack;
	int length;
} IndiciesKeeper;

/*!
	@function	allocKeeper
	@discussion	Allocates an IndiciesKeeper to which an arbitrary number of
				IndiciesRecords can be added.
	@result		Returns a data structure representing the IndiciesKeeper.
*/
IndiciesKeeper allocKeeper();

/*!
	@function	freeKeeper
	@discussion	Frees the IndiciesKeeper and all IndiciesRecords associated with
				it.
	@param		keeper
				The IndiciesKeeper whose records are to be freed.
*/
void freeKeeper(IndiciesKeeper *keeper);

/*!
	@function	addToKeeper
	@discussion	Adds an IndiciesRecord to the IndiciesKeeper, the IndiciesRecord
				will stay in memory for as long as the IndiciesKeeper.
	@param		keeper
				The IndiciesKeeper to add records to.
	@param		record
				The IndiciesRecord to be added.
*/
void addToKeeper(IndiciesKeeper *keeper, IndiciesRecord record);
