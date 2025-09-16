const express = require("express");
const mysql = require("mysql2");
const cors = require("cors");

const app = express();

// Middleware
app.use(express.json());
app.use(express.urlencoded({ extended: false }));
app.use(cors({
    origin: '*',
    methods: ['GET', 'POST', 'PUT', 'DELETE'],
    allowedHeaders: ['Content-Type', 'Accept']
}));

const PORT = process.env.PORT || 3001;

// Database connection
const connection = mysql.createConnection({
    host: "localhost",
    user: "root",
    password: "",
    database: "library_management_system"
});

connection.connect((err) => {
    if (err) {
        console.error('Database connection failed:', err);
        return;
    }
    console.log('Connected to MySQL database: library_management_system');
});

// Error handler
const handleError = (res, err, message = "Server error") => {
    console.error('Database Error:', err);
    res.status(500).json({ msg: message, error: err.message });
};

// ============= CATEGORIES ENDPOINTS =============
app.get("/api/categories", (req, res) => {
    console.log('GET /api/categories requested');
    connection.query("SELECT * FROM categories ORDER BY name", (err, rows) => {
        if (err) return handleError(res, err, 'Failed to fetch categories');
        console.log(`Returned ${rows.length} categories`);
        res.json(rows);
    });
});

app.post('/api/categories', (req, res) => {
    const { name, description } = req.body;
    console.log('POST /api/categories:', req.body);

    if (!name || name.trim() === '') {
        return res.status(400).json({ msg: 'Name is required' });
    }

    connection.query(
        `INSERT INTO categories (name, description, created_at) VALUES (?, ?, NOW())`,
        [name.trim(), description?.trim() || null],
        (err, result) => {
            if (err) {
                if (err.code === 'ER_DUP_ENTRY') {
                    return res.status(400).json({ msg: 'Category name already exists' });
                }
                return handleError(res, err, 'Failed to create category');
            }
            console.log(`Created category: ${name} with ID: ${result.insertId}`);
            res.json({ msg: `Successfully created category: ${name}`, id: result.insertId });
        }
    );
});

app.put('/api/categories/:id', (req, res) => {
    const { id } = req.params;
    const { name, description } = req.body;
    console.log(`PUT /api/categories/${id}:`, req.body);

    if (!name || name.trim() === '') {
        return res.status(400).json({ msg: 'Name is required' });
    }

    connection.query(
        `UPDATE categories SET name = ?, description = ?, updated_at = NOW() WHERE id = ?`,
        [name.trim(), description?.trim() || null, id],
        (err, result) => {
            if (err) {
                if (err.code === 'ER_DUP_ENTRY') {
                    return res.status(400).json({ msg: 'Category name already exists' });
                }
                return handleError(res, err, 'Failed to update category');
            }
            if (result.affectedRows === 0) {
                return res.status(404).json({ msg: 'Category not found' });
            }
            console.log(`Updated category ID: ${id}`);
            res.json({ msg: `Successfully updated category: ${name}` });
        }
    );
});

app.delete('/api/categories/:id', (req, res) => {
    const { id } = req.params;
    console.log(`DELETE /api/categories/${id}`);

    connection.query(`DELETE FROM categories WHERE id = ?`, [id], (err, result) => {
        if (err) return handleError(res, err, 'Failed to delete category');
        if (result.affectedRows === 0) {
            return res.status(404).json({ msg: 'Category not found' });
        }
        console.log(`Deleted category ID: ${id}`);
        res.json({ msg: 'Category deleted successfully' });
    });
});

// ============= BOOKS ENDPOINTS =============
app.get("/api/books", (req, res) => {
    console.log('GET /api/books requested');
    connection.query(`
        SELECT b.*, c.name as category 
        FROM books b 
        LEFT JOIN categories c ON b.category_id = c.id 
        ORDER BY b.title
    `, (err, rows) => {
        if (err) return handleError(res, err, 'Failed to fetch books');

        const books = rows.map(row => ({
            id: row.id,
            title: row.title,
            author: row.author,
            isbn: row.isbn,
            publisher: row.publisher,
            publication_year: row.publication_year,
            quantity: row.quantity,
            available: row.available,
            category: row.category,
            location: row.location,
            description: row.description,
            created_at: row.created_at,
            updated_at: row.updated_at
        }));

        console.log(`Returned ${books.length} books`);
        res.json(books);
    });
});

app.post('/api/books', (req, res) => {
    const { title, author, isbn, publisher, publication_year, quantity, category, location, description } = req.body;
    console.log('POST /api/books:', req.body);

    if (!title || title.trim() === '') {
        return res.status(400).json({ msg: 'Title is required' });
    }

    // Find category_id if category is provided
    if (category) {
        connection.query(
            `SELECT id FROM categories WHERE name = ?`,
            [category],
            (err, categoryResult) => {
                if (err) return handleError(res, err, 'Failed to find category');

                const categoryId = categoryResult.length > 0 ? categoryResult[0].id : null;
                const bookQuantity = quantity || 1;

                connection.query(
                    `INSERT INTO books (title, author, isbn, publisher, publication_year, quantity, available, category_id, location, description, created_at) 
                     VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, NOW())`,
                    [title.trim(), author?.trim() || null, isbn?.trim() || null, publisher?.trim() || null,
                     publication_year || null, bookQuantity, bookQuantity, categoryId, location?.trim() || null, description?.trim() || null],
                    (err, result) => {
                        if (err) {
                            if (err.code === 'ER_DUP_ENTRY') {
                                return res.status(400).json({ msg: 'ISBN already exists' });
                            }
                            return handleError(res, err, 'Failed to create book');
                        }
                        console.log(`Created book: ${title} with ID: ${result.insertId}`);
                        res.json({ msg: `Successfully created book: ${title}`, id: result.insertId });
                    }
                );
            }
        );
    } else {
        const bookQuantity = quantity || 1;
        connection.query(
            `INSERT INTO books (title, author, isbn, publisher, publication_year, quantity, available, category_id, location, description, created_at) 
             VALUES (?, ?, ?, ?, ?, ?, ?, NULL, ?, ?, NOW())`,
            [title.trim(), author?.trim() || null, isbn?.trim() || null, publisher?.trim() || null,
             publication_year || null, bookQuantity, bookQuantity, location?.trim() || null, description?.trim() || null],
            (err, result) => {
                if (err) {
                    if (err.code === 'ER_DUP_ENTRY') {
                        return res.status(400).json({ msg: 'ISBN already exists' });
                    }
                    return handleError(res, err, 'Failed to create book');
                }
                console.log(`Created book: ${title} with ID: ${result.insertId}`);
                res.json({ msg: `Successfully created book: ${title}`, id: result.insertId });
            }
        );
    }
});

app.put('/api/books/:id', (req, res) => {
    const { id } = req.params;
    const { title, author, isbn, publisher, publication_year, quantity, category, location, description } = req.body;
    console.log(`PUT /api/books/${id}:`, req.body);

    if (!title || title.trim() === '') {
        return res.status(400).json({ msg: 'Title is required' });
    }

    if (category) {
        connection.query(
            `SELECT id FROM categories WHERE name = ?`,
            [category],
            (err, categoryResult) => {
                if (err) return handleError(res, err, 'Failed to find category');

                const categoryId = categoryResult.length > 0 ? categoryResult[0].id : null;

                connection.query(
                    `UPDATE books SET title = ?, author = ?, isbn = ?, publisher = ?, publication_year = ?, 
                     quantity = ?, category_id = ?, location = ?, description = ?, updated_at = NOW() WHERE id = ?`,
                    [title.trim(), author?.trim() || null, isbn?.trim() || null, publisher?.trim() || null,
                     publication_year || null, quantity || 1, categoryId, location?.trim() || null, description?.trim() || null, id],
                    (err, result) => {
                        if (err) {
                            if (err.code === 'ER_DUP_ENTRY') {
                                return res.status(400).json({ msg: 'ISBN already exists' });
                            }
                            return handleError(res, err, 'Failed to update book');
                        }
                        if (result.affectedRows === 0) {
                            return res.status(404).json({ msg: 'Book not found' });
                        }
                        console.log(`Updated book ID: ${id}`);
                        res.json({ msg: `Successfully updated book: ${title}` });
                    }
                );
            }
        );
    } else {
        connection.query(
            `UPDATE books SET title = ?, author = ?, isbn = ?, publisher = ?, publication_year = ?, 
             quantity = ?, category_id = NULL, location = ?, description = ?, updated_at = NOW() WHERE id = ?`,
            [title.trim(), author?.trim() || null, isbn?.trim() || null, publisher?.trim() || null,
             publication_year || null, quantity || 1, location?.trim() || null, description?.trim() || null, id],
            (err, result) => {
                if (err) {
                    if (err.code === 'ER_DUP_ENTRY') {
                        return res.status(400).json({ msg: 'ISBN already exists' });
                    }
                    return handleError(res, err, 'Failed to update book');
                }
                if (result.affectedRows === 0) {
                    return res.status(404).json({ msg: 'Book not found' });
                }
                console.log(`Updated book ID: ${id}`);
                res.json({ msg: `Successfully updated book: ${title}` });
            }
        );
    }
});

app.delete('/api/books/:id', (req, res) => {
    const { id } = req.params;
    console.log(`DELETE /api/books/${id}`);

    // Check if book has active borrowings
    connection.query(
        `SELECT COUNT(*) as count FROM borrowings WHERE book_id = ? AND status IN ('Borrowed', 'Overdue')`,
        [id],
        (err, result) => {
            if (err) return handleError(res, err, 'Failed to check borrowings');

            if (result[0].count > 0) {
                return res.status(400).json({ msg: 'Cannot delete book with active borrowings' });
            }

            connection.query(`DELETE FROM books WHERE id = ?`, [id], (err, result) => {
                if (err) return handleError(res, err, 'Failed to delete book');
                if (result.affectedRows === 0) {
                    return res.status(404).json({ msg: 'Book not found' });
                }
                console.log(`Deleted book ID: ${id}`);
                res.json({ msg: 'Book deleted successfully' });
            });
        }
    );
});

// ============= MEMBERS ENDPOINTS =============
app.get("/api/members", (req, res) => {
    console.log('GET /api/members requested');
    connection.query("SELECT * FROM members ORDER BY name", (err, rows) => {
        if (err) return handleError(res, err, 'Failed to fetch members');
        console.log(`Returned ${rows.length} members`);
        res.json(rows);
    });
});

app.post('/api/members', (req, res) => {
    const { name, email, phone, address, member_type } = req.body;
    console.log('POST /api/members:', req.body);

    if (!name || name.trim() === '' || !email || email.trim() === '') {
        return res.status(400).json({ msg: 'Name and email are required' });
    }

    // Generate member ID
    const memberType = member_type || 'Student';
    const prefix = memberType.substring(0, 3).toUpperCase();

    // Get next sequential number for this member type
    connection.query(
        `SELECT member_id FROM members WHERE member_id LIKE ? ORDER BY member_id DESC LIMIT 1`,
        [`${prefix}%`],
        (err, result) => {
            if (err) return handleError(res, err, 'Failed to generate member ID');

            let nextNumber = 1;
            if (result.length > 0) {
                const lastId = result[0].member_id;
                const lastNumber = parseInt(lastId.substring(3));
                nextNumber = lastNumber + 1;
            }

            const memberId = `${prefix}${nextNumber.toString().padStart(3, '0')}`;
            const expiryDate = new Date();
            expiryDate.setFullYear(expiryDate.getFullYear() + 1); // 1 year from now

            // Set max_books based on member type
            let maxBooks = 5;
            switch (memberType) {
                case 'Faculty': maxBooks = 10; break;
                case 'Staff': maxBooks = 7; break;
                case 'Public': maxBooks = 3; break;
                default: maxBooks = 5; break;
            }

            connection.query(
                `INSERT INTO members (member_id, name, email, phone, address, member_type, max_books, expiry_date, created_at) 
                 VALUES (?, ?, ?, ?, ?, ?, ?, ?, NOW())`,
                [memberId, name.trim(), email.trim(), phone?.trim() || null, address?.trim() || null,
                 memberType, maxBooks, expiryDate.toISOString().split('T')[0]],
                (err, result) => {
                    if (err) {
                        if (err.code === 'ER_DUP_ENTRY') {
                            return res.status(400).json({ msg: 'Email address already exists' });
                        }
                        return handleError(res, err, 'Failed to add member');
                    }
                    console.log(`Added member: ${name} with ID: ${memberId}`);
                    res.json({ msg: `Successfully added member: ${name}`, id: result.insertId, member_id: memberId });
                }
            );
        }
    );
});

app.put('/api/members/:id', (req, res) => {
    const { id } = req.params;
    const { name, email, phone, address, member_type, status } = req.body;
    console.log(`PUT /api/members/${id}:`, req.body);

    if (!name || name.trim() === '' || !email || email.trim() === '') {
        return res.status(400).json({ msg: 'Name and email are required' });
    }

    // Set max_books based on member type
    let maxBooks = 5;
    const memberType = member_type || 'Student';
    switch (memberType) {
        case 'Faculty': maxBooks = 10; break;
        case 'Staff': maxBooks = 7; break;
        case 'Public': maxBooks = 3; break;
        default: maxBooks = 5; break;
    }

    connection.query(
        `UPDATE members SET name = ?, email = ?, phone = ?, address = ?, member_type = ?, max_books = ?, 
         status = ?, updated_at = NOW() WHERE id = ?`,
        [name.trim(), email.trim(), phone?.trim() || null, address?.trim() || null,
         memberType, maxBooks, status || 'Active', id],
        (err, result) => {
            if (err) {
                if (err.code === 'ER_DUP_ENTRY') {
                    return res.status(400).json({ msg: 'Email address already exists' });
                }
                return handleError(res, err, 'Failed to update member');
            }
            if (result.affectedRows === 0) {
                return res.status(404).json({ msg: 'Member not found' });
            }
            console.log(`Updated member ID: ${id}`);
            res.json({ msg: `Successfully updated member: ${name}` });
        }
    );
});

app.delete('/api/members/:id', (req, res) => {
    const { id } = req.params;
    console.log(`DELETE /api/members/${id}`);

    // Check if member has active borrowings
    connection.query(
        `SELECT COUNT(*) as count FROM borrowings WHERE member_id = ? AND status IN ('Borrowed', 'Overdue')`,
        [id],
        (err, result) => {
            if (err) return handleError(res, err, 'Failed to check borrowings');

            if (result[0].count > 0) {
                return res.status(400).json({ msg: 'Cannot delete member with active borrowings' });
            }

            connection.query(`DELETE FROM members WHERE id = ?`, [id], (err, result) => {
                if (err) return handleError(res, err, 'Failed to delete member');
                if (result.affectedRows === 0) {
                    return res.status(404).json({ msg: 'Member not found' });
                }
                console.log(`Deleted member ID: ${id}`);
                res.json({ msg: 'Member deleted successfully' });
            });
        }
    );
});

// ============= BORROWINGS ENDPOINTS =============
app.get("/api/borrowings", (req, res) => {
    console.log('GET /api/borrowings requested');
    connection.query(`
        SELECT br.*, b.title as book_title, b.author as book_author, m.name as member_name, m.member_id, m.member_type 
        FROM borrowings br 
        LEFT JOIN books b ON br.book_id = b.id 
        LEFT JOIN members m ON br.member_id = m.id 
        ORDER BY br.borrow_date DESC, br.created_at DESC
    `, (err, rows) => {
        if (err) return handleError(res, err, 'Failed to fetch borrowings');

        const borrowings = rows.map(row => ({
            id: row.id,
            book_title: row.book_title,
            book_author: row.book_author,
            member_name: row.member_name,
            member_id: row.member_id,
            member_type: row.member_type,
            borrow_date: row.borrow_date,
            due_date: row.due_date,
            return_date: row.return_date,
            status: row.status,
            fine_amount: parseFloat(row.fine_amount) || 0,
            notes: row.notes,
            issued_by: row.issued_by,
            returned_to: row.returned_to,
            created_at: row.created_at,
            updated_at: row.updated_at
        }));

        console.log(`Returned ${borrowings.length} borrowings`);
        res.json(borrowings);
    });
});

app.post('/api/borrowings', (req, res) => {
    const { book_title, member_name, due_date, status, notes, fine_amount } = req.body;
    console.log('POST /api/borrowings:', req.body);

    if (!book_title || !member_name) {
        return res.status(400).json({ msg: 'Book and member are required' });
    }

    // Find book_id and member_id
    Promise.all([
        new Promise((resolve, reject) => {
            connection.query(`SELECT id, available FROM books WHERE title = ?`, [book_title], (err, result) => {
                if (err) reject(err);
                else resolve(result.length > 0 ? result[0] : null);
            });
        }),
        new Promise((resolve, reject) => {
            connection.query(`SELECT id, member_type, max_books FROM members WHERE name = ?`, [member_name], (err, result) => {
                if (err) reject(err);
                else resolve(result.length > 0 ? result[0] : null);
            });
        })
    ]).then(([book, member]) => {
        if (!book || !member) {
            return res.status(400).json({ msg: 'Book or member not found' });
        }

        // Check if book is available (only for new borrowings, not for editing existing ones)
        if (book.available <= 0 && (!status || status === 'Borrowed')) {
            return res.status(400).json({ msg: 'Book is not available' });
        }

        // Check member borrowing limit (only for new borrowings)
        if (!status || status === 'Borrowed') {
            connection.query(
                `SELECT COUNT(*) as count FROM borrowings WHERE member_id = ? AND status IN ('Borrowed', 'Overdue')`,
                [member.id],
                (err, result) => {
                    if (err) return handleError(res, err, 'Failed to check member borrowing limit');

                    if (result[0].count >= member.max_books) {
                        return res.status(400).json({ msg: `Member has reached borrowing limit of ${member.max_books} books` });
                    }

                    // Calculate due date if not provided
                    let finalDueDate = due_date;
                    if (!finalDueDate) {
                        const borrowDays = getBorrowingDays(member.member_type);
                        const dueDate = new Date();
                        dueDate.setDate(dueDate.getDate() + borrowDays);
                        finalDueDate = dueDate.toISOString().split('T')[0];
                    }

                    // Insert borrowing record
                    connection.query(
                        `INSERT INTO borrowings (book_id, member_id, borrow_date, due_date, status, notes, fine_amount, issued_by, created_at) 
                         VALUES (?, ?, CURDATE(), ?, ?, ?, ?, 'System', NOW())`,
                        [book.id, member.id, finalDueDate, status || 'Borrowed', notes?.trim() || null, fine_amount || 0],
                        (err, result) => {
                            if (err) return handleError(res, err, 'Failed to create borrowing');

                            // Update book availability (only for borrowed status)
                            if (!status || status === 'Borrowed') {
                                connection.query(
                                    `UPDATE books SET available = available - 1 WHERE id = ?`,
                                    [book.id],
                                    (err) => {
                                        if (err) console.error('Failed to update book availability:', err);
                                    }
                                );
                            }

                            console.log(`Created borrowing for ${book_title} by ${member_name} with ID: ${result.insertId}`);
                            res.json({ msg: 'Successfully created borrowing', id: result.insertId });
                        }
                    );
                }
            );
        } else {
            // For non-borrowed status, don't check limits
            let finalDueDate = due_date;
            if (!finalDueDate) {
                const borrowDays = getBorrowingDays(member.member_type);
                const dueDate = new Date();
                dueDate.setDate(dueDate.getDate() + borrowDays);
                finalDueDate = dueDate.toISOString().split('T')[0];
            }

            connection.query(
                `INSERT INTO borrowings (book_id, member_id, borrow_date, due_date, status, notes, fine_amount, issued_by, created_at) 
                 VALUES (?, ?, CURDATE(), ?, ?, ?, ?, 'System', NOW())`,
                [book.id, member.id, finalDueDate, status, notes?.trim() || null, fine_amount || 0],
                (err, result) => {
                    if (err) return handleError(res, err, 'Failed to create borrowing');
                    console.log(`Created borrowing for ${book_title} by ${member_name} with ID: ${result.insertId}`);
                    res.json({ msg: 'Successfully created borrowing', id: result.insertId });
                }
            );
        }
    }).catch(err => handleError(res, err, 'Failed to process borrowing'));
});

app.put('/api/borrowings/:id', (req, res) => {
    const { id } = req.params;
    const { book_title, member_name, due_date, status, notes, fine_amount } = req.body;
    console.log(`PUT /api/borrowings/${id}:`, req.body);

    // Get current borrowing info first
    connection.query(
        `SELECT br.*, b.id as current_book_id, m.id as current_member_id, br.status as current_status
         FROM borrowings br
         LEFT JOIN books b ON br.book_id = b.id
         LEFT JOIN members m ON br.member_id = m.id
         WHERE br.id = ?`,
        [id],
        (err, currentResult) => {
            if (err) return handleError(res, err, 'Failed to fetch current borrowing');
            if (currentResult.length === 0) {
                return res.status(404).json({ msg: 'Borrowing not found' });
            }

            const currentBorrowing = currentResult[0];

            Promise.all([
                new Promise((resolve, reject) => {
                    connection.query(`SELECT id FROM books WHERE title = ?`, [book_title], (err, result) => {
                        if (err) reject(err);
                        else resolve(result.length > 0 ? result[0].id : null);
                    });
                }),
                new Promise((resolve, reject) => {
                    connection.query(`SELECT id FROM members WHERE name = ?`, [member_name], (err, result) => {
                        if (err) reject(err);
                        else resolve(result.length > 0 ? result[0].id : null);
                    });
                })
            ]).then(([bookId, memberId]) => {
                if (!bookId || !memberId) {
                    return res.status(400).json({ msg: 'Book or member not found' });
                }

                // Update borrowing record
                const returnDate = (status === 'Returned') ? 'CURDATE()' : 'NULL';
                const returnedTo = (status === 'Returned') ? "'System'" : 'NULL';

                connection.query(
                    `UPDATE borrowings SET book_id = ?, member_id = ?, due_date = ?, status = ?, 
                     notes = ?, fine_amount = ?, return_date = ${returnDate}, returned_to = ${returnedTo}, updated_at = NOW() WHERE id = ?`,
                    [bookId, memberId, due_date, status || 'Borrowed', notes?.trim() || null, fine_amount || 0, id],
                    (err, result) => {
                        if (err) return handleError(res, err, 'Failed to update borrowing');
                        if (result.affectedRows === 0) {
                            return res.status(404).json({ msg: 'Borrowing not found' });
                        }

                        // Update book availability based on status changes
                        const oldStatus = currentBorrowing.current_status;
                        const newStatus = status || 'Borrowed';

                        if (oldStatus === 'Borrowed' && newStatus === 'Returned') {
                            // Book returned - increase availability
                            connection.query(
                                `UPDATE books SET available = available + 1 WHERE id = ?`,
                                [bookId],
                                (err) => {
                                    if (err) console.error('Failed to update book availability:', err);
                                }
                            );
                        } else if (oldStatus === 'Returned' && newStatus === 'Borrowed') {
                            // Book borrowed again - decrease availability
                            connection.query(
                                `UPDATE books SET available = available - 1 WHERE id = ?`,
                                [bookId],
                                (err) => {
                                    if (err) console.error('Failed to update book availability:', err);
                                }
                            );
                        }

                        console.log(`Updated borrowing ID: ${id}`);
                        res.json({ msg: 'Successfully updated borrowing' });
                    }
                );
            }).catch(err => handleError(res, err, 'Failed to process borrowing update'));
        }
    );
});

app.delete('/api/borrowings/:id', (req, res) => {
    const { id } = req.params;
    console.log(`DELETE /api/borrowings/${id}`);

    // Get borrowing info before deletion to update book availability
    connection.query(
        `SELECT book_id, status FROM borrowings WHERE id = ?`,
        [id],
        (err, result) => {
            if (err) return handleError(res, err, 'Failed to fetch borrowing');
            if (result.length === 0) {
                return res.status(404).json({ msg: 'Borrowing not found' });
            }

            const borrowing = result[0];

            connection.query(`DELETE FROM borrowings WHERE id = ?`, [id], (err, result) => {
                if (err) return handleError(res, err, 'Failed to delete borrowing');
                if (result.affectedRows === 0) {
                    return res.status(404).json({ msg: 'Borrowing not found' });
                }

                // If the deleted borrowing was active (Borrowed/Overdue), increase book availability
                if (borrowing.status === 'Borrowed' || borrowing.status === 'Overdue') {
                    connection.query(
                        `UPDATE books SET available = available + 1 WHERE id = ?`,
                        [borrowing.book_id],
                        (err) => {
                            if (err) console.error('Failed to update book availability:', err);
                        }
                    );
                }

                console.log(`Deleted borrowing ID: ${id}`);
                res.json({ msg: 'Borrowing deleted successfully' });
            });
        }
    );
});

// ============= ADVANCED BORROWING OPERATIONS =============

// Get overdue borrowings
app.get("/api/borrowings/overdue", (req, res) => {
    console.log('GET /api/borrowings/overdue requested');
    connection.query(`
        SELECT br.*, b.title as book_title, m.name as member_name, m.email, m.phone,
               DATEDIFF(CURDATE(), br.due_date) as days_overdue
        FROM borrowings br 
        JOIN books b ON br.book_id = b.id 
        JOIN members m ON br.member_id = m.id 
        WHERE br.due_date < CURDATE() AND br.status = 'Borrowed'
        ORDER BY days_overdue DESC
    `, (err, rows) => {
        if (err) return handleError(res, err, 'Failed to fetch overdue borrowings');
        console.log(`Returned ${rows.length} overdue borrowings`);
        res.json(rows);
    });
});

// Return a book
app.post('/api/borrowings/:id/return', (req, res) => {
    const { id } = req.params;
    const { returned_to, notes } = req.body;
    console.log(`POST /api/borrowings/${id}/return:`, req.body);

    // Get borrowing details
    connection.query(
        `SELECT br.*, b.id as book_id, br.due_date, m.id as member_id
         FROM borrowings br
         JOIN books b ON br.book_id = b.id
         JOIN members m ON br.member_id = m.id
         WHERE br.id = ? AND br.status IN ('Borrowed', 'Overdue')`,
        [id],
        (err, result) => {
            if (err) return handleError(res, err, 'Failed to fetch borrowing');
            if (result.length === 0) {
                return res.status(404).json({ msg: 'Active borrowing not found' });
            }

            const borrowing = result[0];
            const today = new Date();
            const dueDate = new Date(borrowing.due_date);
            const daysOverdue = Math.max(0, Math.floor((today - dueDate) / (1000 * 60 * 60 * 24)));
            const fineAmount = daysOverdue * 1.00; // $1 per day

            // Update borrowing record
            connection.query(
                `UPDATE borrowings SET return_date = CURDATE(), status = 'Returned', 
                 returned_to = ?, fine_amount = ?, notes = CONCAT(COALESCE(notes, ''), ?) WHERE id = ?`,
                [returned_to || 'System', fineAmount, notes ? `\nReturn notes: ${notes}` : '', id],
                (err, result) => {
                    if (err) return handleError(res, err, 'Failed to return book');

                    // Update book availability
                    connection.query(
                        `UPDATE books SET available = available + 1 WHERE id = ?`,
                        [borrowing.book_id],
                        (err) => {
                            if (err) console.error('Failed to update book availability:', err);
                        }
                    );

                    // Create fine record if applicable
                    if (fineAmount > 0) {
                        connection.query(
                            `INSERT INTO fines (member_id, borrowing_id, fine_type, amount, description, created_at)
                             VALUES (?, ?, 'Overdue', ?, ?, NOW())`,
                            [borrowing.member_id, id, fineAmount, `Book returned ${daysOverdue} days late`],
                            (err) => {
                                if (err) console.error('Failed to create fine record:', err);
                            }
                        );
                    }

                    console.log(`Book returned for borrowing ID: ${id}, fine: ${fineAmount}`);
                    res.json({
                        msg: 'Book returned successfully',
                        fine_amount: fineAmount,
                        days_overdue: daysOverdue
                    });
                }
            );
        }
    );
});

// ============= RESERVATIONS ENDPOINTS =============
app.get("/api/reservations", (req, res) => {
    console.log('GET /api/reservations requested');
    connection.query(`
        SELECT r.*, b.title as book_title, m.name as member_name 
        FROM reservations r 
        LEFT JOIN books b ON r.book_id = b.id 
        LEFT JOIN members m ON r.member_id = m.id 
        ORDER BY r.reservation_date DESC
    `, (err, rows) => {
        if (err) return handleError(res, err, 'Failed to fetch reservations');
        console.log(`Returned ${rows.length} reservations`);
        res.json(rows);
    });
});

// ============= FINES ENDPOINTS =============
app.get("/api/fines", (req, res) => {
    console.log('GET /api/fines requested');
    connection.query(`
        SELECT f.*, m.name as member_name, m.member_id, br.id as borrowing_id
        FROM fines f 
        LEFT JOIN members m ON f.member_id = m.id 
        LEFT JOIN borrowings br ON f.borrowing_id = br.id 
        ORDER BY f.created_at DESC
    `, (err, rows) => {
        if (err) return handleError(res, err, 'Failed to fetch fines');
        console.log(`Returned ${rows.length} fines`);
        res.json(rows);
    });
});

// Pay a fine
app.post('/api/fines/:id/pay', (req, res) => {
    const { id } = req.params;
    const { paid_amount } = req.body;
    console.log(`POST /api/fines/${id}/pay:`, req.body);

    connection.query(
        `UPDATE fines SET paid_amount = ?, paid_date = CURDATE(), 
         status = CASE WHEN ? >= amount THEN 'Paid' ELSE 'Pending' END WHERE id = ?`,
        [paid_amount, paid_amount, id],
        (err, result) => {
            if (err) return handleError(res, err, 'Failed to process payment');
            if (result.affectedRows === 0) {
                return res.status(404).json({ msg: 'Fine not found' });
            }
            console.log(`Fine payment processed for ID: ${id}, amount: ${paid_amount}`);
            res.json({ msg: 'Fine payment processed successfully' });
        }
    );
});

// ============= STATISTICS ENDPOINTS =============
app.get("/api/statistics/dashboard", (req, res) => {
    console.log('GET /api/statistics/dashboard requested');

    const queries = [
        'SELECT COUNT(*) as total_books FROM books',
        'SELECT COUNT(*) as total_members FROM members WHERE status = "Active"',
        'SELECT COUNT(*) as active_borrowings FROM borrowings WHERE status IN ("Borrowed", "Overdue")',
        'SELECT COUNT(*) as overdue_books FROM borrowings WHERE status = "Overdue" OR (status = "Borrowed" AND due_date < CURDATE() )',
        'SELECT SUM(amount - paid_amount) as outstanding_fines FROM fines WHERE status = "Pending"',
        'SELECT category, COUNT(*) as count FROM books b LEFT JOIN categories c ON b.category_id = c.id GROUP BY category',
        'SELECT member_type, COUNT(*) as count FROM members WHERE status = "Active" GROUP BY member_type',
        'SELECT status, COUNT(*) as count FROM borrowings GROUP BY status'
    ];

    Promise.all(queries.map(query =>
        new Promise((resolve, reject) => {
            connection.query(query, (err, result) => {
                if (err) reject(err);
                else resolve(result);
            });
        })
    )).then(results => {
        const stats = {
            totals: {
                books: results[0][0].total_books,
                members: results[1][0].total_members,
                active_borrowings: results[2][0].active_borrowings,
                overdue_books: results[3][0].overdue_books,
                outstanding_fines: parseFloat(results[4][0].outstanding_fines) || 0
            },
            books_by_category: results[5],
            members_by_type: results[6],
            borrowings_by_status: results[7]
        };

        console.log('Dashboard statistics generated');
        res.json(stats);
    }).catch(err => handleError(res, err, 'Failed to generate statistics'));
});

// ============= UTILITY FUNCTIONS =============
function getBorrowingDays(memberType) {
    switch (memberType) {
        case 'Faculty': return 30;
        case 'Staff': return 21;
        case 'Public': return 7;
        default: return 14; // Student
    }
}

// ============= BULK OPERATIONS =============

// Bulk update overdue status
app.post('/api/borrowings/update-overdue', (req, res) => {
    console.log('POST /api/borrowings/update-overdue requested');

    connection.query(
        `UPDATE borrowings SET status = 'Overdue' 
         WHERE status = 'Borrowed' AND due_date < CURDATE()`,
        (err, result) => {
            if (err) return handleError(res, err, 'Failed to update overdue status');
            console.log(`Updated ${result.affectedRows} borrowings to overdue status`);
            res.json({
                msg: `Updated ${result.affectedRows} borrowings to overdue status`,
                updated_count: result.affectedRows
            });
        }
    );
});

// ============= SEARCH ENDPOINTS =============

// Search books
app.get("/api/search/books", (req, res) => {
    const { q } = req.query;
    console.log(`GET /api/search/books requested with query: ${q}`);

    if (!q || q.trim() === '') {
        return res.status(400).json({ msg: 'Search query is required' });
    }

    const searchTerm = `%${q.trim()}%`;
    connection.query(`
        SELECT b.*, c.name as category 
        FROM books b 
        LEFT JOIN categories c ON b.category_id = c.id 
        WHERE b.title LIKE ? OR b.author LIKE ? OR b.isbn LIKE ? OR c.name LIKE ?
        ORDER BY b.title
    `, [searchTerm, searchTerm, searchTerm, searchTerm], (err, rows) => {
        if (err) return handleError(res, err, 'Failed to search books');
        console.log(`Found ${rows.length} books matching query: ${q}`);
        res.json(rows);
    });
});

// Search members
app.get("/api/search/members", (req, res) => {
    const { q } = req.query;
    console.log(`GET /api/search/members requested with query: ${q}`);

    if (!q || q.trim() === '') {
        return res.status(400).json({ msg: 'Search query is required' });
    }

    const searchTerm = `%${q.trim()}%`;
    connection.query(`
        SELECT * FROM members 
        WHERE name LIKE ? OR email LIKE ? OR member_id LIKE ? OR phone LIKE ?
        ORDER BY name
    `, [searchTerm, searchTerm, searchTerm, searchTerm], (err, rows) => {
        if (err) return handleError(res, err, 'Failed to search members');
        console.log(`Found ${rows.length} members matching query: ${q}`);
        res.json(rows);
    });
});

// ============= REPORTS ENDPOINTS =============

// Popular books report
app.get("/api/reports/popular-books", (req, res) => {
    console.log('GET /api/reports/popular-books requested');
    connection.query(`
        SELECT b.title, b.author, c.name as category, COUNT(br.id) as borrow_count,
               b.quantity, b.available
        FROM books b
        LEFT JOIN categories c ON b.category_id = c.id
        LEFT JOIN borrowings br ON b.id = br.book_id
        GROUP BY b.id
        ORDER BY borrow_count DESC, b.title
        LIMIT 20
    `, (err, rows) => {
        if (err) return handleError(res, err, 'Failed to generate popular books report');
        console.log(`Generated popular books report with ${rows.length} entries`);
        res.json(rows);
    });
});

// Member activity report
app.get("/api/reports/member-activity", (req, res) => {
    console.log('GET /api/reports/member-activity requested');
    connection.query(`
        SELECT m.member_id, m.name, m.member_type, 
               COUNT(br.id) as total_borrowings,
               COUNT(CASE WHEN br.status = 'Borrowed' THEN 1 END) as current_borrowings,
               COUNT(CASE WHEN br.status = 'Overdue' THEN 1 END) as overdue_count,
               COALESCE(SUM(f.amount - f.paid_amount), 0) as outstanding_fines
        FROM members m
        LEFT JOIN borrowings br ON m.id = br.member_id
        LEFT JOIN fines f ON m.id = f.member_id AND f.status = 'Pending'
        WHERE m.status = 'Active'
        GROUP BY m.id
        ORDER BY total_borrowings DESC, m.name
    `, (err, rows) => {
        if (err) return handleError(res, err, 'Failed to generate member activity report');
        console.log(`Generated member activity report with ${rows.length} entries`);
        res.json(rows);
    });
});

// ============= HEALTH CHECK ENDPOINT =============
app.get("/api/health", (req, res) => {
    connection.query('SELECT 1', (err, result) => {
        if (err) {
            res.status(500).json({
                status: "ERROR",
                message: "Database connection failed",
                error: err.message,
                timestamp: new Date().toISOString()
            });
        } else {
            res.json({
                status: "OK",
                message: "Library Management System API is running",
                database: "Connected to library_management_system",
                version: "1.0.0",
                timestamp: new Date().toISOString()
            });
        }
    });
});

// ============= ERROR HANDLING MIDDLEWARE =============
app.use((err, req, res, next) => {
    console.error('Unhandled error:', err);
    res.status(500).json({
        msg: 'Internal server error',
        error: process.env.NODE_ENV === 'development' ? err.message : 'Something went wrong'
    });
});

// Express 5-safe 404 handler (replace the old app.use('*', ...) with this)
app.use((req, res) => {
    res.status(404).json({
        msg: 'Route not found',
        path: req.originalUrl,
        method: req.method
    });
});

// ============= SERVER STARTUP =============
// Listen on all interfaces
app.listen(PORT, '0.0.0.0', () => {
    console.log(`=================================`);
    console.log(`Library Management Server running on port ${PORT}`);
    console.log(`Local:   http://localhost:${PORT}`);
    console.log(`Network: http://0.0.0.0:${PORT}`);
    console.log(`Health:  http://localhost:${PORT}/api/health`);
    console.log(`=================================`);
    console.log(`Available Endpoints:`);
    console.log(`  Categories:  /api/categories`);
    console.log(`  Books:       /api/books`);
    console.log(`  Members:     /api/members`);
    console.log(`  Borrowings:  /api/borrowings`);
    console.log(`  Fines:       /api/fines`);
    console.log(`  Statistics:  /api/statistics/dashboard`);
    console.log(`  Search:      /api/search/books?q=term`);
    console.log(`  Reports:     /api/reports/popular-books`);
    console.log(`=================================`);
});
