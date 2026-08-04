import { Injectable } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { CreateContactMessageDto } from './dto/create-contact-message.dto';
import { ContactMessage } from './schemas/contact-message.schema';

@Injectable()
export class ContactService {
  constructor(
    @InjectModel(ContactMessage.name)
    private readonly contactMessageModel: Model<ContactMessage>,
  ) {}

  async create(dto: CreateContactMessageDto): Promise<void> {
    await this.contactMessageModel.create(dto);
  }
}
