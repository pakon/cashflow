// Generated by O/R mapper generator ver 0.1(cashflow)

package org.tmurakam.cashflow.ormapper;

import java.util.*;
import android.content.ContentValues;
import android.database.*;
import android.database.sqlite.*;

import org.tmurakam.cashflow.ormapper.ORRecord;
import org.tmurakam.cashflow.models.*;

public class TransactionBase extends ORRecord {
    public final static String tableName = "Transactions";

	public int pid;
	protected boolean isInserted = false;

	public int asset;
	public int dst_asset;
	public long date;
	public int type;
	public int category;
	public double value;
	public String description;
	public String memo;


	/**
	  @brief Migrate database table
	  @return YES - table was newly created, NO - table already exists
	*/
	public static boolean migrate() {
		String[] columnTypes = {
		"asset", "INTEGER",
		"dst_asset", "INTEGER",
		"date", "DATE",
		"type", "INTEGER",
		"category", "INTEGER",
		"value", "REAL",
		"description", "TEXT",
		"memo", "TEXT",
		};

		return migrate(tableName, columnTypes);
	}

	// Read operations

	/**
	  @brief get the record matches the id

	  @param pid Primary key of the record
	  @return record
	*/
	public Transaction find(int pid) {
		SQLiteDatabase db = Database.instance();

		String[] param = { Integer.toString(pid) };
		Cursor cursor = db.rawQuery("SELECT * FROM " + tableName + " WHERE key = ?;", param);

		Transaction e = null;
		cursor.moveToFirst();
		if (!cursor.isAfterLast()) {
			e = new Transaction();
			e._loadRow(cursor);
		}
		cursor.close();
 
		return e;
	}

	/**
	   @brief get all records
	   @return array of all record
	*/
	public static ArrayList<Transaction> find_all() {
		return find_cond(null, null);
	}

	/**
	   @brief get all records matches the conditions

	   @param cond Conditions (WHERE phrase and so on)
	   @return array of records
	*/
	public static ArrayList<Transaction> find_cond(String cond) {
		return find_cond(cond, null);
	}

	/**
	   @brief get all records match the conditions

	   @param cond Conditions (WHERE phrase and so on)
	   @return array of records
	*/
	public static ArrayList<Transaction> find_cond(String cond, String[] param) {
		String sql;
		sql = "SELECT * FROM " + tableName;
		if (cond != null) {
			sql += " ";
			sql += cond;
		}
		SQLiteDatabase db = Database.instance();
		Cursor cursor = db.rawQuery(sql, param);
		cursor.moveToFirst();

		ArrayList<Transaction> array = new ArrayList<Transaction>();

		while (!cursor.isAfterLast()) {
			Transaction e = new Transaction();
			e._loadRow(cursor);
			array.add(e);
			cursor.moveToNext();
		}
		cursor.close();

		return array;
	}

	protected void _loadRow(Cursor cursor) {
		this.pid = cursor.getInt(0);
		this.asset = cursor.getInt(1);
		this.dst_asset = cursor.getInt(2);
		this.date = Database.str2date(cursor.getString(3));
		this.type = cursor.getInt(4);
		this.category = cursor.getInt(5);
		this.value = cursor.getDouble(6);
		this.description = cursor.getString(7);
		this.memo = cursor.getString(8);

		isInserted = true;
	}

	// Create operations

	public void insert() {
		super.insert();

		SQLiteDatabase db = Database.instance();

		// TBD: pid should be long?
		this.pid = (int)db.insert(tableName, "key", getContentValues());

		isInserted = true;
	}

	// Update operations

	public void update() {
		SQLiteDatabase db = Database.instance();
		db.beginTransaction();

		ContentValues cv = getContentValues();

		String[] whereArgs = { Long.toString(pid) };
		db.update(tableName, cv, "key = ?", whereArgs);

		db.endTransaction();
	}

	private ContentValues getContentValues()
	{
		ContentValues cv = new ContentValues(8);
		cv.put("asset", this.asset);
		cv.put("dst_asset", this.dst_asset);
		cv.put("date", Database.date2str(this.date));
		cv.put("type", this.type);
		cv.put("category", this.category);
		cv.put("value", this.value);
		cv.put("description", this.description);
		cv.put("memo", this.memo);

		return cv;
	}

	// Delete operations

	/**
	   @brief Delete record
	*/
	public void delete() {
		SQLiteDatabase db = Database.instance();

		String[] whereArgs = { Long.toString(pid) };
		db.delete(tableName, "WHERE key = ?", whereArgs);
	}

	/**
	   @brief Delete all records
	*/
	public void delete_cond(String cond) {
		SQLiteDatabase db = Database.instance();

		if (cond == null) {
			cond = "";
		}
		String sql = "DELETE FROM " + tableName + " " + cond;
		db.execSQL(sql);
	}
}
